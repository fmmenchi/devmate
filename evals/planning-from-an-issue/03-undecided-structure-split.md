# 03 — A structural decision the issue does not settle, split with the decision first

## Setup

A fresh session is given `fixtures/repo.md` as the repository and issue `jot-21` with its
triage from `fixtures/issues.md`.

## Query

> plan this issue

## Expected behaviour with the skill

`outcome: split`, `criterion: 2`. The evidence names the decision the issue leaves open: where
notes are synced through — a shared folder, a remote service, a new dependency such as a CRDT
library — and how concurrent edits merge, since _"should not lose anything"_ rules out
last-write-wins on the whole file. The first issue is that decision, with alternatives as its
acceptance criterion's subject, and depends on nothing. Every later issue — a per-note
`updatedAt` in `src/types.ts`, the merge in `src/store.ts`, the transport — lists the first in
`dependsOn`.

## Baseline without the skill

A plan that picks a transport silently — typically a synced folder — and implements
last-write-wins on `notes.json`, contradicting the issue's second sentence. Observable: no
decision named as open; a new dependency or a schema change inside the plan's `files` with no
alternative weighed.

## Pass criterion

`plan.json` has `outcome: split` and `split.criterion: 2`; the first issue in order has an
empty `dependsOn` and is about the open decision, not about code; every other issue's
`dependsOn` contains the first issue's `key`. **Plannability, checked:** the first issue, fed
back to the skill, returns `outcome: plan`.
