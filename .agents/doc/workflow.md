# Workflow — agent rules

ADRs, commits, branches, hooks and CI. Decided in
[ADR 0002](../../apps/docusaurus/docs/adr/0002-an-nx-workspace-on-the-shared-platform-model.md).

## Decisions

A structural change — the shape of the repository, a shared schema, a dependency or toolchain, a
gate, a rule every skill or step must follow — gets an ADR in `apps/docusaurus/docs/adr/`
**before** the change. Conventions and the index are in `adr/index.md`; add the new row there.
Never rewrite an accepted ADR: supersede it.

## Commits and branches

- **Conventional commits**, enforced by commitlint on `commit-msg`. Lowercase subject. The type
  vocabulary is `tools/commit/types.mjs` — one list for commitlint and the branch gate.
- **Branches:** `<type>/<kebab-description>`, ending with the issue number when there is one.
  Never `main`.
- **Rebase and merge.** No merge commits.

## Hooks and CI

- `pre-push` checks the names of **the refs being pushed** (stdin), then runs `pnpm run check`.
- CI (`.github/workflows/ci.yml`) runs the same `pnpm run check`, with `@fmmenchi/gh-actions`
  bricks pinned by commit SHA — never a tag. To update a brick, move the SHA in its own change.
- **Never bypass a hook**, never push, never merge.
