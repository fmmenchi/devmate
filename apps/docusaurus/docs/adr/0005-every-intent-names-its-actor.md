# ADR 0005 — Every intent names its actor

- **Status:** proposed
- **Date:** 2026-10-15
- **Deciders:** Fabio Menchicchi

## Context and problem statement

The core is the only writer to GitHub, and every write is an intent: a file that moves
`prepared → sent → attributed | escalated`, read back before it counts. All writes leave under
one token, so on GitHub every issue, comment and pull request devmate creates has the same
author. Without more, nobody can tell later which step produced a write, in which run, or whether
a human authorised it. And a tracker operation that looks like one action — splitting an issue
into several — is in fact many independent writes, any of which can fail.

## Decision

**Every intent carries an `actor`, required from `schemaVersion` 1:**

```json
"actor": {
  "step": "plan",
  "runId": "…",
  "authorizedBy": { "gate": "split", "human": "fmmenchi", "at": "2026-10-15T14:02:00Z" }
}
```

- **The core derives it** from the run's state. It is never a parameter: an attribution the
  caller declares is one anyone can forge.
- **`authorizedBy` is `null` only under a named rule** that allows the write unattended, and the
  intent names that rule. Never null by default.
- **Required, not optional.** Outcomes are later correlated per step and per gate; an optional
  field is a permanent hole in that history.
- **Mirrored in the marker** the core writes into the GitHub body, next to the intent's
  idempotency key, so the tracker itself says who acted.

**A multi-write operation is a set of intents, never one call.** Each write has a stable
idempotency key — the run id plus the artefact's own key — checked against the marker before
creating, so a resumed run completes instead of duplicating. Writes go in dependency order. A
partly applied operation ends in its own resumable state, never in silence.

Skills write nothing to the tracker and carry no actor; their role is the step being run.

## Consequences

- The intent schema is the first one to write, and it carries `actor` from its first version.
- Splitting an issue gets a terminal state for "approved, not fully applied", distinct from an
  invalid plan.
