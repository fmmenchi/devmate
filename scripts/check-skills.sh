#!/usr/bin/env bash
# The skill gate (ADR 0003): ai-skills' check-skills.sh at the SHA pinned in
# .ai-skills-ref, run against THIS repository, then devmate's own check that
# every JSON example in a SKILL.md validates against its schema (ADR 0004).
#
# Fail-closed throughout. If the pinned gate cannot be obtained, or does not
# check the root it is given, this fails — it never skips and passes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { echo "ERROR  skill gate: $1" >&2; exit 1; }

sha="$(tr -d '[:space:]' < "$ROOT/.ai-skills-ref" 2>/dev/null)" || die ".ai-skills-ref is missing"
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || die ".ai-skills-ref must hold a full 40-character commit SHA, got '$sha'"

cache="$ROOT/.cache/ai-skills/$sha"
gate="$cache/scripts/check-skills.sh"

if [ ! -f "$gate" ]; then
  mkdir -p "$ROOT/.cache/ai-skills"
  tmp="$(mktemp -d "$ROOT/.cache/ai-skills/.tmp.XXXXXX")"
  trap 'rm -rf "$tmp"' EXIT

  # The sibling clone is beside the MAIN checkout, which a worktree is not:
  # resolve it from the common git dir. Same bytes as GitHub, no network.
  common="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  sibling="${AI_SKILLS_DIR:-${common:+$(dirname "$common")/../ai-skills}}"

  if [ -n "$sibling" ] && git -C "$sibling" cat-file -e "$sha^{commit}" 2>/dev/null; then
    git -C "$sibling" archive "$sha" | tar -x -C "$tmp"
  else
    curl -fsSL "https://codeload.github.com/fmmenchi/ai-skills/tar.gz/$sha" \
      | tar -xz -C "$tmp" --strip-components=1 \
      || die "cannot obtain ai-skills@$sha — no local clone holds it and GitHub did not serve it"
  fi
  [ -f "$tmp/scripts/check-skills.sh" ] || die "ai-skills@$sha has no scripts/check-skills.sh"
  rm -rf "$cache" && mv "$tmp" "$cache"
  trap - EXIT
fi

# A gate that ignores its argument would check ai-skills' own skills and pass
# on ours unseen. Probe it on a root whose skills/ is empty: it must say so.
probe="$(mktemp -d)"
mkdir "$probe/skills"
probe_out="$(bash "$gate" "$probe" 2>&1 || true)"
rm -rf "$probe"
grep -q 'skills/ is empty' <<<"$probe_out" \
  || die "ai-skills@$sha does not check the root it is given — move .ai-skills-ref to a commit whose gate takes one"

bash "$gate" "$ROOT"
node "$ROOT/scripts/check-skill-examples.mjs"
