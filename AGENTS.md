# AGENTS.md

Operating contract for this repository. This file is the always-on hub: what devmate is, the
commands, the gate that must pass, and an index of topic rules. Open a `.agents/doc/*.md` spoke
only when your task touches that topic. Human documentation — the ADRs included — is the
Docusaurus site under `apps/docusaurus/docs/`.

## Project

`devmate` — takes a GitHub issue through agents (triage, plan, implement, verify, review) to a
**draft** pull request, and scores the work. **A human merges. Always.** The core is a
TypeScript CLI that is the only writer to GitHub; the judgement steps are pipeline skills in
`skills/`, run through a runner adapter; a VS Code extension comes later.

devmate depends on `ai-skills` (the skill gate) and `shared-platform` (the docs plugin, the CI
bricks), both pinned. Neither depends on devmate.

- **Monorepo:** Nx 23 — pnpm workspaces + TypeScript project references. Every project is created
  by its official generator, never by hand.
- **Tooling:** TypeScript 6 · pnpm 11 · Node ≥ 24 · Prettier.

## Setup & commands

```bash
pnpm install                    # deps, and the git hooks (husky runs on prepare)
pnpm run check                  # THE gate: format, Nx targets, skill gate — must be green
pnpm run commit                 # commitizen, for humans; agents write the message directly
pnpm nx build @fmmenchi/devmate-docs   # the docs site (also: start, serve)
```

`@fmmenchi/*` comes from GitHub Packages: a token in `~/.npmrc` locally. Run tasks through Nx
(`pnpm nx …`), never the underlying tool.

## Rules whose breach is silent

- **`skills/` is the product, not your toolbox.** Never move a pipeline skill into
  `.agents/skills/` or any folder a tool scans: it would fire while you work here.
  ([ADR 0003](./apps/docusaurus/docs/adr/0003-pipeline-skills-their-evals-and-their-gate.md))
- **A skill never depends on Node.** ([ADR 0003](./apps/docusaurus/docs/adr/0003-pipeline-skills-their-evals-and-their-gate.md))
- **An attribution is derived, never passed in** — an intent's `actor` comes from the run's
  state. ([ADR 0005](./apps/docusaurus/docs/adr/0005-every-intent-names-its-actor.md))
- **A structural decision gets an ADR first**, and is not made until it is written.
- **`AGENTS.md` only.** Never add a `CLAUDE.md`.
  ([ADR 0001](./apps/docusaurus/docs/adr/0001-agents-md-is-the-only-agent-contract.md))

## Topic index (`.agents/doc/`)

| Spoke                                         | Open it when the task touches…                                                |
| --------------------------------------------- | ----------------------------------------------------------------------------- |
| [architecture](./.agents/doc/architecture.md) | where a file or project goes, Nx projects, tags and boundaries, the docs site |
| [skills](./.agents/doc/skills.md)             | writing or editing a pipeline skill, its evals, its schemas, the skill gate   |
| [workflow](./.agents/doc/workflow.md)         | ADRs, commits, branches, hooks, CI, pull requests                             |
| [known-issues](./.agents/doc/known-issues.md) | something behaves unexpectedly — read it _before_ debugging                   |

## How we work

- **Never work on `main`.** Semantic branch, conventional commits, rebase and merge.
- **Never bypass a hook.** `--no-verify` and its friends are forbidden; a failing gate gets fixed.
- **Never push, never merge.** Fabio does both.

<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

# General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

## Scaffolding & Generators

- For scaffolding tasks (creating apps, libs, project structure, setup), ALWAYS invoke the `nx-generate` skill FIRST before exploring or calling MCP tools

## When to use nx_docs

- USE for: advanced config options, unfamiliar flags, migration guides, plugin configuration, edge cases
- DON'T USE for: basic generator syntax (`nx g @nx/react:app`), standard commands, things you already know
- The `nx-generate` skill handles generator discovery internally - don't call nx_docs just to look up generator syntax

<!-- nx configuration end-->
