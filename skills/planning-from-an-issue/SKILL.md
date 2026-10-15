---
name: planning-from-an-issue
description: Turns a triaged issue into either one implementation plan — the chosen approach, the files it touches, and the alternatives rejected with their reasons — or a proposal to split the issue into smaller ones, written as plan.md and plan.json for devmate's core to validate. Use when a triage marks an issue actionable and not human. Never while implementing — a plan is not a diff — and never to run commands, open issues or touch the tracker: the core does all three.
---

# Planning from an issue

One decision: **which approach, and why not the others — or why this is not one change.**
The output is read twice: by the core, which validates `plan.json` before anyone sees it, and,
when triage said `complex`, by a human at the plan gate, who reads `plan.md`. Write for both.

## 1. What you read, and what you do not

- `issue.json` — devmate's schema, not the tracker's payload.
- `triage.json` — complexity, confidence, risk class.
- The repository at the base SHA named in `manifest.json`, read-only.

Not the issue's comments or linked pull requests unless the run directory provides them to
this step. Not the network. You know devmate's schemas; you know nothing of the API behind them.

## 2. Decide the outcome first: `plan` or `split`

Split when **any** of these holds, and say which:

1. The issue asks for more than one behaviour that could be merged, reviewed and reverted on
   its own.
2. The approach needs a structural decision the issue does not settle — a new dependency, a
   schema or public-API change — and the rest of the work depends on it. The decision becomes
   its own first issue.
3. The change spans subsystems that share no files and no tests.
4. Your own estimate of the diff exceeds what one reviewer can check against one plan. State
   the estimate; the core compares it with the diff later.

Otherwise plan. A split is never a way to avoid a hard plan: each proposed issue must itself be
plannable — given back to you as an issue, §2 would answer `plan` — and the first one must be
startable without the others.

## 3. A plan

- **The approach**, in a paragraph a reviewer could attack.
- **At least one alternative, rejected with its reason.** "Simpler" is not a reason; name what
  the alternative breaks or costs.
- **Files.** Every path that changes. A path that does not exist yet is marked `new`; the core
  rejects any other path it cannot find.
- **Tests.** Which test proves the behaviour. For a bug, name the reproducing test that must
  fail before the change and pass after it — the core records both.
- **Verification.** What the project's own gate must show. Name the gate's checks; never write
  a command. The core resolves commands from the declared gate, not from this file.
- **Out of scope**, explicitly — what a reader might expect this plan to do and it does not.
- **Assumptions**, separated from what you verified in the repository.

## 4. A split

- **Why**: the criterion from §2 that holds, with the evidence.
- **The issues**, in order: title, a body written as an issue a stranger could pick up, the
  acceptance criterion, and `dependsOn`. Each is small enough that §2 would answer `plan`.
- **What is lost** by splitting — a refactor done twice, an interim state that ships.

You do not open these issues. The core asks the human through the split gate, and only on
approval writes them to the tracker.

## 5. Output

`plan.md` for the human, `plan.json` for the core; same content, the JSON authoritative.

```json
{
  "schemaVersion": 1,
  "issue": "<id from issue.json>",
  "outcome": "plan | split",
  "plan": {
    "approach": "…",
    "alternatives": [{ "approach": "…", "rejectedBecause": "…" }],
    "files": [{ "path": "…", "change": "…", "new": false }],
    "tests": [{ "path": "…", "proves": "…", "failsBefore": true }],
    "verification": ["<gate check name>"],
    "outOfScope": ["…"],
    "assumptions": ["…"],
    "estimatedDiffLines": 0
  },
  "split": {
    "criterion": 1,
    "evidence": "…",
    "issues": [{ "key": "a", "title": "…", "body": "…", "acceptance": "…", "dependsOn": [] }],
    "cost": "…"
  }
}
```

Exactly one of `plan` and `split` is present. If the core rejects the file, the step runs once
more with the rejection; a second rejection ends the run in `plan.invalid`. Never answer the
rejection by deleting what failed — an alternative removed to pass the schema is a worse plan.
