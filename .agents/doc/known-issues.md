# Known issues — agent rules

Read this **before** debugging something odd. Each entry: the symptom, the cause, what to do.

## `@fmmenchi/nx-docusaurus` `site` generator writes `workspace:*` for itself

**Symptom:** after generating the site, `pnpm install` fails with
`ERR_PNPM_WORKSPACE_PKG_NOT_FOUND … "@fmmenchi/nx-docusaurus@workspace:*"`.
**Cause:** the generator assumes it runs inside `shared-platform`, where the plugin is a
workspace package. In a consumer it is a registry package.
**Do:** pin the published version in `apps/docusaurus/package.json` (done: `0.0.20`). The fix
belongs in `shared-platform`'s generator, not here.

## Nx's AI setup brings back what ADR 0001 and 0002 removed

**Symptom:** a `CLAUDE.md`, or skill copies under `.cursor/`, `.github/`, `.opencode/`, or a
`monitor-ci` skill reappear after an Nx command (workspace creation, `configure-ai-agents`, a
migration).
**Cause:** Nx generates them by default.
**Do:** delete them. `AGENTS.md` is the only contract; `.agents/skills/` is the only skill source;
there is no Nx Cloud.

## The skill gate fails on `.ai-skills-ref`

**Symptom:** `pnpm run check` ends with `ai-skills@<sha> does not check the root it is given`,
or `cannot obtain ai-skills@<sha>`.
**Cause:** the pinned `ai-skills` commit predates `check-skills.sh [root]`, or it exists only in
a local clone and CI cannot download it.
**Do:** move `.ai-skills-ref` to a commit on `ai-skills`' `main` whose gate takes a root. Never
weaken the wrapper to let it pass.

## Hooks are repository-wide, worktrees are not

**Symptom:** a checkout of an older branch commits without commitlint running.
**Cause:** husky sets `core.hooksPath` in the shared git config; a checkout whose tree has no
`.husky/` has no hooks to run.
**Do:** work on branches based on a `main` that has `.husky/`.

## pnpm refuses install scripts not listed

**Symptom:** `ERR_PNPM_IGNORED_BUILDS` on install.
**Cause:** pnpm 11 runs no dependency build script unless `pnpm-workspace.yaml` `allowBuilds`
lists it.
**Do:** add the package with `true` only if it genuinely needs to build; otherwise `false`.
