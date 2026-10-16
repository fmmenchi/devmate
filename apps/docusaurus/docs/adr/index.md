---
title: Architecture Decision Records
sidebar_position: 0
---

# Architecture Decision Records

Structural decisions for devmate, one file per decision, numbered sequentially:
`NNNN-<kebab-title>.md`.

**No structural decision is made until it is written here.** Not the commit that implements it,
not a plan that recommends it, not an agent spoke that states it afterwards. A decision that
lives only in a conversation will be re-litigated.

- **Statuses:** `proposed` → `accepted` | `rejected` | `superseded by NNNN`. An ADR may stay
  `proposed` indefinitely: a framed open question is worth more than a decision taken to close it.
- **Never rewrite an accepted ADR: supersede it.** A number is an identifier, referenced from
  commits and pull requests; it is never reused or renumbered.
- **Structural** means that reversing it later would cost more than the decision: the shape of
  the repository, a schema the core and the skills share, a dependency or toolchain entering, a
  gate, a rule every future skill or step must follow.

| ADR                                                            | Title                                                    | Status   |
| -------------------------------------------------------------- | -------------------------------------------------------- | -------- |
| [0001](./0001-agents-md-is-the-only-agent-contract.md)         | `AGENTS.md` is the only agent contract, indexed by topic | proposed |
| [0002](./0002-an-nx-workspace-on-the-shared-platform-model.md) | An Nx workspace, on the shared-platform model            | proposed |
| [0003](./0003-pipeline-skills-their-evals-and-their-gate.md)   | Pipeline skills, their evals, and their gate             | proposed |
| [0004](./0004-schemas-are-the-contract.md)                     | Schemas are the contract                                 | proposed |
| [0005](./0005-every-intent-names-its-actor.md)                 | Every intent names its actor                             | proposed |
