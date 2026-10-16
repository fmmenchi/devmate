# Architecture — agent rules

Where things go. The decisions behind these rules are ADRs
[0002](../../apps/docusaurus/docs/adr/0002-an-nx-workspace-on-the-shared-platform-model.md),
[0003](../../apps/docusaurus/docs/adr/0003-pipeline-skills-their-evals-and-their-gate.md) and
[0004](../../apps/docusaurus/docs/adr/0004-schemas-are-the-contract.md); this file states them.

## The tree

```
AGENTS.md                         the agent contract (hub) — .agents/doc/ holds the spokes
.agents/skills/                   skills for working ON devmate (Nx's); one source, no mirrors
skills/<name>/SKILL.md            pipeline skills — the PRODUCT, loaded by the runner only
evals/<name>/                     ≥3 evals per pipeline skill, with fixtures
schemas/<artefact>.schema.json    the contract between core, skills and UIs
packages/                         Nx library and tool projects
apps/docusaurus/                  the docs site; ADRs in docs/adr/
scripts/                          repository tooling — the skill gate
tools/commit/                     the commit-type vocabulary, shared by both hooks
```

## Rules

- **Create projects with their generator** (`pnpm nx g …`), never by hand, and give each a
  `scope:` tag. Look at `pnpm nx show projects` before adding one.
- **The core never depends on a UI.** View-model types live in a contracts library both import.
- **A project's human docs go in its own `docs/` folder** with a `doc:<category>` tag; the site
  assembles them. Workspace-level docs go in `apps/docusaurus/docs/`. Never copy a doc into the
  site by hand.
- **Agent rules go in `.agents/doc/`, human explanation in the site.** A spoke links to its ADR
  and never re-decides it.
- **`dist/`, `build/`, `.nx/`, `.cache/` are generated.** Never edit or commit them.
