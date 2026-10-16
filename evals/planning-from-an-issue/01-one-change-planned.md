# 01 — One change, planned as one

## Setup

A fresh session is given `fixtures/repo.md` as the repository and issue `jot-12` with its
triage from `fixtures/issues.md`.

## Query

> plan this issue

## Expected behaviour with the skill

`outcome: plan`. The approach adds a `--json` branch to `list` in `src/cli.ts` and prints
`JSON.stringify` of the loaded notes, leaving `formatNote` untouched. At least one alternative is
rejected with a reason that names a cost — e.g. a `formatNotes(notes, mode)` in `src/format.ts`,
rejected because it changes a function two callers and a test rely on, for one flag. Every path
in `files` exists in the fixture or is marked `new`. A test proves the flag's output parses as
JSON. `verification` names gate checks — `typecheck`, `lint`, `test` — and no command.
`outOfScope` says what was not done, such as `--json` on other commands. `estimatedDiffLines`
is present.

## Baseline without the skill

A to-do list of edits: _"1. add flag 2. update list 3. add test 4. run `npm test`"_. Observable:
no alternative, or one with no reason; verification written as a shell command; nothing out of
scope; no estimate; no machine-readable output.

## Pass criterion

`plan.json` validates against `schemas/plan.schema.json` with `outcome: plan`; at least one
alternative has a non-empty `rejectedBecause` that names a cost; every `files[].path` exists in
the fixture or has `new: true`; `verification` contains no string that is a shell command.
