# devmate

A local developer-productivity assistant that reviews the work behind your issues and grades it
against your own rubric, right on your machine.

devmate takes a GitHub issue through agents — triage, plan, implement, verify, review — to a
**draft** pull request, and scores the result. A human merges, always.

## Getting started

```bash
pnpm install        # needs a GitHub Packages token for @fmmenchi/* in ~/.npmrc
pnpm run check      # the gate
pnpm nx start @fmmenchi/devmate-docs   # the documentation site, ADRs included
```

Documentation lives in `apps/docusaurus/docs/`. Agents start from [`AGENTS.md`](./AGENTS.md).
