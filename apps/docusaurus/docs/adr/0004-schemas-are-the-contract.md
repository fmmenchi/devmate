# ADR 0004 — Schemas are the contract

- **Status:** proposed
- **Date:** 2026-10-15
- **Deciders:** Fabio Menchicchi

## Context and problem statement

The core and the skills exchange files — `issue.json`, `triage.json`, `plan.json`, findings,
intents, gate requests and responses — and the core and the UIs exchange view models. Each of
those is a contract between two sides that are written separately, one of them by a model. A
skill teaches its output by example, and a model copies the example more faithfully than it
follows the prose around it.

## Decision

**`schemas/` at the root holds one JSON Schema per artefact**, `schemas/<artefact>.schema.json`,
each carrying `schemaVersion`. They are the only definition: the core validates every file it
reads or writes against them, and a contracts library derives its TypeScript types from them, so
the core and the UIs share one type per view model.

**Every JSON example inside a `SKILL.md` names its schema and validates against it.** An example
block is fenced as ` ```json <artefact> `; the gate validates it against
`schemas/<artefact>.schema.json` and fails on a mismatch or on a JSON example that names no
schema. An example that contradicts its own rule is a defect the gate catches, not a reviewer.

**The core and the UIs share one workspace.** A view model that changes in the core changes in
the UI in the same pull request; tags keep the core from depending on any UI.

## Consequences

- The schema check is devmate's own, added after the `ai-skills` gate in
  `scripts/check-skills.sh`. It needs a JSON Schema validator, so it runs on Node — tooling, not a
  skill (ADR 0003).
- A skill whose output has two shapes shows two examples, one per shape.
- Changing a schema is a change to every side that reads it, in one pull request.
