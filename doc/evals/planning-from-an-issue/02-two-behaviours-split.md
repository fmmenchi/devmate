# 02 — Two behaviours in one issue, split

## Setup

A fresh session is given `fixtures/repo.md` as the repository and issue `jot-15` with its
triage from `fixtures/issues.md`.

## Query

> plan this issue

## Expected behaviour with the skill

`outcome: split`, `criterion: 1`. The evidence says that export and import share no code path —
one reads the store and writes a file, the other parses a file and writes the store — and that
either can be merged and reverted without the other. Two issues, each with a body a stranger
could pick up and an acceptance criterion; neither depends on the other. `cost` names what is
lost, such as two passes over `cli.ts` usage text. No issue is opened: the output says the core
asks for approval.

## Baseline without the skill

One plan covering both commands, or — when the agent has a shell — an attempt to open the two
issues on the tracker itself. Observable: a single plan whose `files` include both a CSV parser
and a Markdown writer; or a `gh issue create` in the transcript.

## Pass criterion

`plan.json` has `outcome: split` and `split.criterion: 1`; exactly two issues, neither with a
non-empty `dependsOn`; no tracker command in the transcript. **Plannability, checked:** each
proposed issue is fed back to the skill as a new `issue.json` with the same triage, and each
returns `outcome: plan`. A proposed issue that returns `split` again fails this eval.
