# ADR 0003 — Pipeline skills, their evals, and their gate

- **Status:** proposed
- **Date:** 2026-10-15
- **Deciders:** Fabio Menchicchi

## Context and problem statement

devmate's pipeline runs skills — triage, plan, implement, verify, review, blast radius, CI
judgement — in the Agent Skills open format. They live here, not in `ai-skills`, because their
output templates change in the same pull request as the core code that parses them (`ai-skills`
ADR 0005). `ai-skills` already has a gate for the format, `scripts/check-skills.sh`.

## Decision

**Pipeline skills live in `skills/<name>/SKILL.md`, a folder no tool discovers.** They are the
product: the runner injects a skill into a step explicitly. They are deliberately not in
`.agents/skills/` or any folder a coding agent scans on its own — a pipeline skill that fired
while someone worked on devmate would be a planner loose in the wrong repository. Skills for
working _on_ devmate go in `.agents/skills/` (ADR 0002).

**Evals live at the root, in `evals/<name>/`** — at least three per skill, with their fixtures.
They execute and they fail; they are tests, not documentation. Nothing that is not the skill
lives in `skills/<name>/`.

**The gate is `ai-skills`' `check-skills.sh`, pinned, and the same everywhere.**

- **One entry point:** `scripts/check-skills.sh`, part of `pnpm run check`.
- **One version:** `.ai-skills-ref` holds an `ai-skills` commit SHA. Moving it is a pull request.
- **One way to get it:** the wrapper materialises that SHA into `.cache/ai-skills/<sha>/` — from a
  sibling `../ai-skills` clone when it holds the SHA, from GitHub otherwise — and runs it against
  this repository's root. Where the bytes come from is an optimisation; they are the same bytes.
- **It fails closed.** No SHA, no cache, no network, or a malformed ref: the gate fails. It never
  skips and passes.

Not a copy: a copy drifts without a sound. Not a submodule: devmate creates a worktree per run,
and a submodule taxes every one of them.

**A skill never depends on Node.** The core, the UIs and the tooling may; a skill that needs
`pnpm install` to work is not portable, and is rejected.

## Consequences

- The pinned `check-skills.sh` must accept the root to check as an argument. Until the pinned
  `ai-skills` commit does, the gate cannot run, and fails.
- An `ai-skills` change to the gate reaches devmate only when `.ai-skills-ref` moves.
