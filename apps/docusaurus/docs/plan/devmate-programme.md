# The devmate programme — plan

- **Status:** revision 3, for review (2026-09-07). Revision 1 went through two fresh-context
  reviews — adversarial, and a UI architect's; revision 2 through a prior-art survey of Max's
  repositories and the analogous systems. All three are kept verbatim under `reviews/`, and what
  each changed is recorded at the end.
- **Read it as (2026-10-16):** revision 3, still for review. Where an
  [ADR](../adr/index.md) decides, the ADR prevails over this text; the eight questions at the end
  remain open.
- **Owner:** Fabio Menchicchi
- **Lives here**, in the product's repository. The harness — `ai-skills` — knows nothing of the
  programme by design; its own decisions stay there, and this plan only asks one of it (D1).

A plan is not a decision. Every structural choice below is marked **D<n>** and gets its own ADR
— in the repository it concerns — _before_ the phase that depends on it. Nothing in this file
authorises a change on its own.

## Goal, stated precisely

Manage the GitHub issues of a repository through agents: take an issue, plan it, implement it,
verify it, review it adversarially, score the result, open a **draft** pull request that closes
the issue on merge. **A human merges. Always.** The issue closes as a consequence of that merge —
`Closes #N` in the PR body — never by a bot.

Three artefacts, three repositories, one dependency direction:

| Artefact                                                             | Repository              | Knows                                                                             |
| -------------------------------------------------------------------- | ----------------------- | --------------------------------------------------------------------------------- |
| **Craft skills** — how to do the work                                | `ai-skills`             | the craft; never the tracker, never the runtime, never devmate                    |
| **devmate** — what to work on, how it went, and its own seven skills | `devmate`               | GitHub, orchestration, evidence, the score, the schemas its skills read and write |
| **UIs** — VS Code first, others later                                | `devmate` (or siblings) | presentation, and the human gates                                                 |

devmate depends on `ai-skills`; `ai-skills` depends on nothing. This is Max's split
(`claude-forge` / `jidoka-code`) and the opposite of `wishew-skills`, where the pipeline knows
the tracker. It is also the shape Max himself moved _to_: his first products were a skill
running inside a Claude session with `gh` in the model's hands, and he abandoned that for an
engine that holds the credentials, executes commands from a digest-frozen plan, and gives the
model no generic shell. **Phase 3 must not regress to "a skill that calls `gh`".**

**Where the pipeline's skills live changed in revision 2.** The seven pipeline skills live in
`devmate/skills/`, in the open format, tested for runtime-agnosticism the same way. A skill whose
output template a devmate script parses must change in the same pull request as that script —
which is exactly `ai-skills`' second admission gate — and the `README` already says _project-scoped
skills in the project_. See D1.

## The shape

```
┌──────────────────────────────────────────────────────────┐
│  UI            VS Code extension · later a menu-bar app   │  renders view models,
│                native surfaces first, a webview if earned │  answers gates
├──────────────────────────────────────────────────────────┤
│  devmate core  CLI: run · answer · resume · cancel        │  GitHub (sole token holder),
│                runs · show · events  (JSON, versioned)    │  orchestration, budgets,
│                run directory = storage, not the contract  │  evidence, score, history,
│                sole writer; every GitHub write an intent  │  process ownership
├──────────────────────────────────────────────────────────┤
│  runner adapter   one invocation per step                 │  (run dir, step, skill, model,
│                   Claude Code --bare · replay · Codex     │   effort, cwd, budget) →
│                   declares its isolation capability       │   events, structured output
├──────────────────────────────────────────────────────────┤
│  skills          devmate/skills (pipeline) · ai-skills    │  the craft
└──────────────────────────────────────────────────────────┘
```

Five lines carry the design:

- **The runner is a boundary, not a feature.** One adapter per runtime, a per-step contract at
  the level of _events and validated structured output_ — never exit codes, never prose. Each
  adapter declares what isolation it can give (an OS sandbox, a worktree, an allowlist) and the
  core plans around that, instead of assuming parity. The Claude adapter runs `--bare` and
  injects skills explicitly: without `--bare`, headless Claude executes the target repository's
  own hooks and MCP servers with no trust prompt, which is a security boundary, not a nicety.
- **The core is a CLI before it is anything else, and every invocation is short.** A run is a
  state machine on disk. `devmate run` advances it until it finishes or reaches a gate, then
  **exits** with `status: waiting`. Nothing ever blocks on a human.
- **The run directory is storage and the forensic record — not the contract.** The core is its
  **sole writer**; reviewers write only their own subdirectory; step files are immutable and a
  later round writes the next number with `supersedes`. UIs consume commands returning versioned
  view models.
- **The core owns the process, the budgets and the credentials.** Worktrees, parallelism, gates,
  cancellation, liveness, fix-round and wall-clock caps, the GitHub token: core. Budgets are
  checked _before_ a launch, in code — a Stop hook that fires after the rounds are spent can only
  refuse to bless the cost, never prevent it, which is what Max measured: prose budgets ran
  60–200% over.
- **Verification is executed by the core from a declared gate, never from text.** The model
  supplies measured values; the commands it measures with are resolved by the core from the
  project's own declared gate, allowlisted by shape. A command reachable from issue text or from
  a model's output is an injection path, and Max found exactly that in his own DoD runner.

## The flow, one issue end to end

**Core** is deterministic code in devmate. **Skill** is judgement, run through the runner.
**Script** is deterministic code bundled with a skill. **Human** is a gate — always a persisted
request/response pair on disk, never an interactive prompt.

| #   | Step               | Who                       | Produces                                                                                                                                               | Notes                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --- | ------------------ | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0   | Manifest           | core                      | `manifest.json`: base SHA, model ids per step, adapter versions, budgets, run id                                                                       | written first                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 1   | Intake             | core                      | `issue.json` — a **devmate-owned schema**, not the GitHub payload; comments and linked PRs kept in a separate file the planner does not see by default | the tracker is laundered here, once                                                                                                                                                                                                                                                                                                                                                                                                 |
| 2   | Triage             | skill                     | `triage.json`: actionable?, complexity `simple · moderate · complex`, confidence, effort tier, **risk class**                                          | low confidence forces the strong tier. Hard-risk classes — security core, data-loss migration, release/tag, cross-repo, unverifiable — are triaged **`human`** and never planned                                                                                                                                                                                                                                                    |
| 3   | Plan               | skill                     | `plan.md` + `plan.json`                                                                                                                                | validated by core: schema; every `files[]` exists or is flagged `new`; ≥1 alternative; issue id matches. Fails → re-run once, then `plan.invalid`                                                                                                                                                                                                                                                                                   |
| 4   | **Plan gate**      | human                     | `gates/plan.request.json` → `gates/plan.response.json`                                                                                                 | **conditional on triage**: `complex` stops here; `simple` and `moderate` run unattended to a draft PR, with a falsifier — if 2 of the first 10 unattended PRs are closed unmerged, `moderate` gets the gate back. Options: `approve` (records `sha256(plan.md)`) · `approve-amended` (core keeps the original and the diff) · `reject {reason}`                                                                                     |
| 5   | Implement          | skill                     | a branch in a worktree **created by core**, the diff                                                                                                   | an action-level allowlist inside the step; the anti-tampering instruction in the skill; for a bug-fix issue the core records **fails-before / passes-after** on the reproducing test                                                                                                                                                                                                                                                |
| 6   | Verify             | core + skill              | `verification/metadata.json`: sha, dirty, per-command exit and duration, **stamped by core**                                                           | commands resolved by core from the declared gate; the skill reads the bundle and cannot run arbitrary strings. Fresh means: postdates the last edit **and** the last failed verify                                                                                                                                                                                                                                                  |
| 7   | Adversarial review | skill ×N                  | `findings/<reviewer>/NNN.json`                                                                                                                         | each reviewer in its **own worktree at the base SHA** — isolation, not read-only: probes and mutation runs are allowed there. Input: `plan.json`, the diff, `verification/`, declared exclusions — never the conversation. **At least one reviewer from another model family.** Caps are never stated in the brief; a capped reviewer writes `truncation.json`, which is a Major                                                    |
| 8   | Consolidate        | **core**                  | `findings.json`                                                                                                                                        | dedup key `(file, hunk, normalised claim)`; highest severity kept; every reporter listed; distinct claims never merged; agreement counts as signal only **across families**; unlocated findings in their own bucket. A reviewer missing from the roster **blocks**. N reports with zero findings yield `review: not measured` unless each carries an _evidence scope / not checked_ section. Tree must still be at the reviewed SHA |
| 9   | Fix                | skill                     | the diff, amended                                                                                                                                      | see the loop                                                                                                                                                                                                                                                                                                                                                                                                                        |
| 10  | Blast radius       | **core script** + skill   | `stale-candidates.json` → `stale.json`                                                                                                                 | the script diffs exported symbols and lists importers, docs and tests that reference them; the skill only judges the candidates. Max's skill-only version measured **zero recall** on 18–55-file changes                                                                                                                                                                                                                            |
| 11  | Score — live       | core                      | `score.json`: per criterion measured / not measured, coverage, the number                                                                              | evidence adapter A. Criteria include **mergeability**, not gate-pass alone: test-file diff (added, modified, skipped), diff size against plan, lint. Critical ⇒ 0; deductions over the consolidated list; the _weights_ are placeholders until Phase 5. Below a coverage floor there is no PR-ready                                                                                                                                 |
| 12  | Pull request       | core                      | the PR, **always draft**: plan, evidence, score, `Closes #N`                                                                                           | every GitHub write is an **intent file** `prepared → sent → attributed                                                                                                                                                                                                                                                                                                                                                              | escalated` with read-back; a lost response never triggers a blind re-create |
| 13  | CI watch           | core (+ skill on request) | `ci.json`: raw check results                                                                                                                           | polling and the ledger are core. A failure enters the loop **only when the human asks**; `judging-ci-failure` then judges _false positive_ or _real_. Not part of Phase 3's exit                                                                                                                                                                                                                                                    |
| 14  | Score — forensic   | core                      | `score.forensic.json`                                                                                                                                  | evidence adapter B: CI results, the PR as it stands. Never averaged with 11                                                                                                                                                                                                                                                                                                                                                         |
| 15  | **Merge**          | human                     | —                                                                                                                                                      | the only shipping gate; a required status check with human approvals that go stale on push; the issue closes with it                                                                                                                                                                                                                                                                                                                |

**The loop, written down.** `6 → 7 → 8 → (9 → 6 → 7 → 8)* → 10 → (9 → 6 → 7 → 8)¹ → 11`. A fix
is followed by re-verification _and_ re-review. **Fix rounds start at 3**, not 5, and are a core
parameter checked before each launch, with a per-step wall clock and a per-run cost (`not
measured` where the runtime reports only tokens). When rounds run out with findings open the run
ends in **`blocked`** with `escalation.json` — score, open findings, per-round delta — and the
draft PR opens with `converged: no`. Never a quiet stop with a fluent summary.

**What is replayable, honestly.** Script and core steps replay from their inputs. Skill steps are
_re-runnable_, with the original transcript kept and `manifest.json` naming the model; each step
records the runtime `session_id` so it can be **resumed** rather than replayed where the runtime
allows.

**Gates.** Two designed — plan (conditional) and merge. Three exceptions with fixed option sets —
CI judgement, rounds exhausted, draft promotion. Every gate is a request file with typed options
and a response file. No timeouts: a run waits.

## The skills, at the right granularity

One skill = one decision boundary. Seven, all in `devmate/skills/`:

| Skill                     | Decision it owns                                                                      | Fires when                                                   | Never when                                                        |
| ------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------------- |
| `triaging-an-issue`       | _is this actionable, how much does it cost, and what class of risk is it?_            | an issue arrives with no sizing                              | a plan already exists                                             |
| `planning-from-an-issue`  | _which approach, and why not the others?_                                             | triage says actionable and not `human`                       | implementing — a plan is not a diff                               |
| `implementing-a-plan`     | _how does this land without breaking the project's own gate?_                         | an approved or unattended plan exists                        | no plan — refuse, do not improvise one                            |
| `verifying-before-done`   | _what does the core's evidence bundle support, and what does it not?_                 | a bundle exists                                              | as a way to run commands — it cannot                              |
| `reviewing-adversarially` | _how does this break?_ — concrete inputs → wrong output, with evidence and confidence | a diff, a plan and a verification bundle exist; own worktree | with the author's context, or without an _evidence scope_ section |
| `checking-blast-radius`   | _which of these candidates now describes behaviour that no longer exists?_            | the core script has produced candidates                      | on the whole tree — the script narrows, the skill judges          |
| `judging-ci-failure`      | _false positive or real?_                                                             | the human asks, on a failing check                           | on its own initiative                                             |

What these skills know, stated without pretence: **devmate's schemas** and nothing of the API
behind them. What is **not** a skill: consolidation, roster, blast-radius candidates, scoring
arithmetic, intake, PR creation, CI polling, verification execution — all core.

`ai-skills` keeps its own criterion untouched and gets only what passes it.

## Choosing models — a process, not a preference

### The method: evaluation-driven, with fixed inputs and a sanitised set

1. **Build the eval set from real issues — and sanitise it.** Five to ten closed issues from
   Fabio's repositories, each with the closing PR as reference and a hand-labelled `sizing` and
   `type` (bug-fix, feature, perf, docs/CI). Strip comments and linked PRs from the issue text —
   on SWE-bench a third of "solved" instances had the answer in the thread. Prefer issues closed
   after the candidate models' cut-offs. Add tests beyond the closing PR's where possible.
2. **Fix the input of every step so steps are separable.** Review on the _reference_ diff;
   implement from the _reference_ plan.
3. **Define the measure per step, computable.** Triage: agreement with labelled sizing and risk.
   Plan: file-set overlap with the reference PR. Implement: the gate passes **and** a mergeability
   rubric — test-file diff, diff size — because gate-pass alone over-predicts merge by ~24 points
   in METR's data. Review: findings matching a change the reference PR made ÷ raised, by family.
   Denominators are `len(cases)`, never "answers received".
4. **Run the matrix**, results in a schema anyone can re-run to the same number.
5. **Pick per step.** Effort first, model second.
6. **Re-run when a model ships.**

Score-versus-outcome correlation is Phase 5's, on devmate's own history.

### What the literature says, corrected twice

- **Cascade, cite the routers as analogy only.** _RouteLLM_ trains routers on ~80k preference
  pairs; _FrugalGPT_ learns thresholds on a scorer. Neither is a hand-written triage on ten
  examples. What transfers is the **shape**: cheap first; escalate on an output signal. Here the
  triage's `confidence: low` escalates _before_ implement, and a failed verify escalates _after_
  — the `wishew:issue` thinking → thinking-deep shape, already in use.
- **Effort before model.** Max pins `effort` per agent; the model is the second lever.
- **Same-family reviewers correlate.** On real PRs LLM reviewers score F1 ≈ 0.07 against 0.85
  on synthetic ones; consensus among same-family models amplifies shared errors; a small model
  beat a mid one at a third of the cost. Hence the cross-family reviewer and the _by family_
  measure.
- **Test tampering is measured behaviour.** A hack rate of 51% fell to 19% with one
  anti-tampering instruction in the Claude 4 system card; the held-out-test gap grows with code
  size. Hence the instruction in the implement skill, the test-file-diff criterion, and held-out
  tests where the set allows.
- **A model judging a model is biased in known ways** (Zheng et al., 2023). Anchor every
  criterion to something computable.

### A starting point, to be replaced by the matrix

| Step               | Start with                                                                             | Why                                              |
| ------------------ | -------------------------------------------------------------------------------------- | ------------------------------------------------ |
| triage             | small, fast                                                                            | classification; its confidence gates upward only |
| plan               | strongest available, high effort                                                       | a wrong plan wastes an implementation            |
| implement          | mid tier, escalating on verify failure                                                 | the cascade, on an output signal                 |
| verify             | small                                                                                  | reads a bundle                                   |
| adversarial review | strong, medium effort, fresh worktree; **plus one from another family, small is fine** | breadth, and decorrelated error                  |
| blast radius       | mid tier                                                                               | judges a candidate list                          |
| score              | none                                                                                   | arithmetic                                       |
| CI judgement       | mid tier, on request                                                                   | one bit                                          |

## Coordination: tools, or not

**Not.** The sequence is plain code in the core. Parallelism only in step 7, and there the
reviewers are isolated by worktree, not by permission. No orchestration library: a `for` loop,
budgets as `if` statements before launch, and files on disk written by one writer — the pattern
OpenHands arrived at after abandoning a pub/sub event stream, and jidoka with a single-writer
actor.

## The core's interface — commands and view models

A UI imports three schemas and calls six commands.

| Command                                           | Returns                                                      | Note                                                   |
| ------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------ |
| `devmate run <repo> <issue>`                      | run id; exits at completion or a gate with `status: waiting` | never blocks on a human                                |
| `devmate answer <run> <gate> <option> [--reason]` | —                                                            | `resume` re-validates the plan hash                    |
| `devmate resume <run>`                            | as `run`                                                     | after a gate, a reboot, an interruption                |
| `devmate cancel <run>`                            | —                                                            | SIGTERM; the step is `cancelled`; the worktree is kept |
| `devmate runs --json`                             | list: status, health, pending gate                           |                                                        |
| `devmate show <run> --json`                       | per-step state, gate, findings grouped, score, ledger, links | the only place status is computed                      |
| `devmate events <run> --follow`                   | NDJSON stream                                                |                                                        |

Every JSON carries `schemaVersion`. Per-step state:
`pending · running · waiting · done · failed · cancelled · truncated · stale · not-measured`.
Per-run `health` from `pid`, heartbeat and artefact presence.

**Process ownership, two stages.** Stage 1, no daemon: the CLI is the parent; `run.json`
records `pid`, `startedAt`, heartbeat; the extension spawns it and on deactivation leaves the run
`interrupted`, resumable. Stage 2, only for a second client: `devmate serve` on a Unix socket,
the same verbs. Write the verbs now, build the daemon later.

`.devmate/runs/` is anchored at `git rev-parse --git-common-dir`. The GitHub token reaches the
core as an environment variable and never a model.

## The runner adapter contract

One invocation per step.

- **Input:** run directory, step, skill, model, effort, working directory, **budget** (turns,
  wall clock, cost where the runtime can report it).
- **Output:** `{ session_id, terminal: success | max_turns | budget | error | killed,
structured_output: validated against the step's schema | absent, cost: { usd | tokens | not
measured }, denials[], transcript_path }`, plus the **event stream** in an agnostic vocabulary
  appended by the core to `events.ndjson`.
- **Declared capability:** the isolation it provides — OS sandbox, worktree, allowlist — so the
  core can decide what may run there.

A missing or invalid structured output makes the step `failed` or `not-measured`; nothing is ever
parsed from prose. A tool-call ledger — commands and exit codes per step — is written beside the
transcript, because legibility is a record of actions, not a narrative.

Adapters, in order: **Claude Code headless, `--bare`, skills injected**; **replay** (a recorded
run, configurable timing, no model — the UI fixture and the first proof of the contract);
**Codex** — needed earlier than revision 2 assumed, because the cross-family reviewer in step 7
wants a second real runtime. See the review questions.

## Debugging and observability

- **One directory per run**, one writer, immutable step files with `supersedes`, `manifest.json`,
  `events.ndjson`, `run.json`, the ledger, the gate files, and every GitHub intent.
- **Failure states are the normal state.** Runner crash, auth expiring mid-run, rate limits, a
  worktree left behind, a dead pid, two runs on one issue, a lost response to a PR create.
- **Deterministic parts are deterministic code, with tests.**
- **Fresh evidence, or no claim** — by SHA, by the core.

## Testing the UI

The **replay adapter** as fixture; extension-host tests with `@vscode/test-cli`; a webview's
React, if one ever exists, tested standalone. Argent as a manual smoke; its reach into a
`vscode-webview://` iframe is unverified and gets a spike before anything depends on it.

## The UI, and the design system

Native surfaces first: `TreeDataProvider` for issues and runs; `withProgress` with native cancel;
`vscode.diff`; `DiagnosticCollection` and `CommentController` for findings; `plan.md` in a real
editor with a notification and a CodeLens for the gate; notifications for exception gates; a
status-bar item for the score. Keyboard-complete and theme-correct by construction; **keyboard-only
operation of the whole loop** is a Phase 4 exit criterion.

The extension **bundles the core's CLI** at the matching version, `extensionKind: ["workspace"]`,
and refuses an unknown `schemaVersion` major with a message.

The design system waits for a screen a tree view cannot carry. When one comes, the preset is
generated from a typed, complete `Record<ColorRole, {vscode, fallback}>`, keyed on the four
theme kinds including high-contrast, with `font-size` decided and tested at 13px — and weighed
once against `@vscode-elements/elements`, which the DS beats only if the same webview must also
ship as a web page.

## Decisions this plan forces

|        | Decision                                                              | Repository  | Recommendation                                                                                                                                                                                                                                                                                                          |
| ------ | --------------------------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **D1** | Where the pipeline's seven skills live.                               | `ai-skills` | **`devmate/skills/`.** They fail `ai-skills`' second gate. The ADR is written before this row is treated as a recommendation.                                                                                                                                                                                           |
| **D2** | The runner contract and the order of adapters.                        | `devmate`   | Event-level, validated structured output, declared isolation. **Claude Code `--bare`, then replay, then Codex** — with Codex possibly pulled into Phase 3 for the cross-family reviewer.                                                                                                                                |
| **D3** | The rubric: one engine, two evidence adapters, mergeability criteria. | `devmate`   | **A at step 11, B at step 14, never averaged.** Coverage reported; a floor for PR-ready; Critical ⇒ 0; weights are placeholders until Phase 5 — Max's −10/−3 were never calibrated and scored a sound 43-file move at 27.                                                                                               |
| **D4** | Human gates.                                                          | `devmate`   | **Plan gate conditional on triage**: `complex` stops, `simple`/`moderate` run unattended to a draft PR with a written falsifier; hard-risk classes are `human` and never planned. Merge requires a status check with human approvals stale on push. CI judgement, rounds exhausted, draft promotion as exception gates. |
| **D5** | Scope of judgement.                                                   | `devmate`   | **Own work first**, explicitly.                                                                                                                                                                                                                                                                                         |
| **D6** | The core's interface to UIs.                                          | `devmate`   | **Commands plus versioned view models; the run directory is storage.**                                                                                                                                                                                                                                                  |
| **D7** | Model selection.                                                      | `devmate`   | **A cascade**, matrix-filled once it exists; triage escalates before, verify failure after; the routers cited as shape only.                                                                                                                                                                                            |

## Phases

### Phase 0 — Foundation _(done, with a caveat)_

On `main`, CI green twice. The caveat is in `known-issues.md`: three merge commits, no pull
request, on the first exercise of the rules that forbid it.

**Remaining exit:** `./install.sh`; `pnpm install` on the main checkout; branch protection with
the `check` job required and direct pushes to `main` refused.

### Phase 1 — Decide _(ADRs, no code)_

Step zero: `devmate`'s skeleton with its ADR 0001 as first commit. Then D1 in `ai-skills`, D2–D7
in `devmate`. The flow checked against one real closed issue. The eval set chosen, sanitised,
labelled, written down.

**Exit:** the ADRs exist; the eval set is a file in `devmate`.

### Phase 2 — The skills _(in `devmate/skills/`)_

The seven, in flow order, evals first. `check-skills.sh` is the gate.

**Exit:** gate green; every skill's three evals run on Claude Code.

### Phase 3 — devmate core _(CLI only)_

The commands, the state machine, budgets in code, the intent ledger, verification from the
declared gate, the Claude adapter with `--bare`, the replay adapter, blast-radius script, adapter
A at step 11. The matrix on the eval set.

**Exit:** one real issue on one of Fabio's repositories, issue in → draft PR out with no manual
step after the plan gate; stopped at the gate, machine rebooted, resumed; a killed run shows
stale; `show --json` and `events --follow` work; the run directory committed as a fixture. **CI
watch is not part of this exit.**

### Phase 4 — The first UI _(VS Code, native surfaces)_

**Exit:** the Phase 3 run from the editor with the gate answered there; the same loop driven by
an extension test against the replay adapter; keyboard-only operation of the whole loop.

### Phase 5 — Calibration

Thresholds and rubric weights from devmate's own history; the matrix re-run per release; the
falsifier on the unattended plan gate evaluated at ten PRs; a second client, if wanted, brings
stage 2 of process ownership.

**Exit:** a threshold with a number and the history that produced it.

## Deliberately not in the plan

- **Merge automation.** Never.
- **Closing issues by bot.**
- **A CI auto-fix loop.** Sweep's ten-attempt loop is the cautionary shape; a CI failure enters
  the loop only when asked.
- **The harness-invokes-itself shape** — a skill with `gh` and push rights. Max left it behind.
- **An orchestration framework**, **a daemon**, **a webview**, until each is earned.
- **Transcript-regex hooks as enforcement.** Budgets live in code before the launch.
- **Telemetry and change contracts** in Max's style.
- **A docs site.** ADR 0004.

## Risks, and what catches each

| Risk                                                    | Caught by                                                                                      |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| A run that dies with its parent                         | persisted gates; `resume`; the reboot test                                                     |
| A score with no evidence behind it                      | coverage, floor, arithmetic in code, SHA by core                                               |
| A verify skill running fewer commands                   | it runs none; the core runs the declared gate                                                  |
| A command reachable from issue or model text            | commands resolved by core, allowlisted by shape                                                |
| Tests modified, skipped or hard-coded to pass           | test-file-diff criterion; held-out tests; the anti-tampering instruction                       |
| Same-family reviewers agreeing on the same mistake      | one cross-family reviewer; agreement counted only across families                              |
| A reviewer that never reports, read as clean            | roster in core; missing file blocks; zero findings without an evidence scope is `not measured` |
| A capped reviewer returning shallow findings fast       | caps never stated; truncation is a Major                                                       |
| Budgets exceeded in prose                               | budgets checked in code before launch; fix rounds start at 3                                   |
| A lost response to a PR create, then a second PR        | intent files with read-back; never a blind re-create                                           |
| Headless Claude running the target repo's hooks         | `--bare`, skills injected explicitly                                                           |
| Findings against a diff they no longer describe         | re-review after every fix; tree checked at the reviewed SHA                                    |
| A cheap triage sending a hard issue down the cheap path | confidence gates upward only; verify failure escalates                                         |
| The plan gate removed and nothing noticing it was wrong | the falsifier: 2 of 10 closed unmerged reinstates it                                           |
| The eval set contaminated by its own answers            | comments and linked PRs stripped; post-cutoff issues preferred                                 |
| Judging people by accident                              | D5                                                                                             |

## Review record

**Adversarial review of revision 1** (15 findings, 14 confirmed) — moved the seven skills to
`devmate`; split the score; per-step runner contract; consolidation and roster into core; the
loop and `blocked`; honest replayability and `manifest.json`; coverage and core-stamped SHAs; eval
measures with reference inputs; the 15× and FrugalGPT corrections; Phase 0 updated; Phase 2 to
one runtime; plan validation enumerated; grouping by hunk.

**UI architect's reflection on revision 1** (11 findings) — gates as persisted state; process
ownership in two stages; the event stream; commands plus view models; native surfaces; typed
gates and the three exception gates; failure states; the replay adapter; bundled core; keyboard.

**Prior-art survey of revision 2** (12 changes; Max's repositories read on disk, seven analogous
systems, the papers cited) — the plan gate conditional on triage with a falsifier, and hard-risk
classes never planned; reviewers isolated by worktree rather than read-only, one from another
family, with evidence scopes; the runner contract at event level with validated structured output
and `--bare`; verification commands resolved by core from a declared gate; budgets in code before
launch, truncation as a Major, exhaustion as `escalation.json`; every GitHub write an intent with
read-back; blast radius as a core script; mergeability criteria in the score and weights deferred
to Phase 5; the eval set sanitised; CI watch demoted out of Phase 3; always a draft PR; five things
copied from Max verbatim and three refused, each with the reason from his own reports.

## For the review

1. **D4** — the plan gate is now _conditional_: `simple` and `moderate` run unattended to a
   draft PR, with a written falsifier. That is Max's measured result (33 of 33 merged, none
   closed) against revision 2's caution. Do you want the first ten runs gated anyway, and the
   falsifier used to remove the gate rather than to restore it?
2. **D2 / step 7** — a reviewer from another model family means a second real runtime in Phase 3,
   not Phase 5. Is Codex acceptable that early, or does one family suffice until the matrix says
   otherwise?
3. **D1** — the seven skills in `devmate/skills/`.
4. **D3** — two scores never averaged; weights as placeholders until Phase 5.
5. **The seven skills** — `checking-blast-radius` is now a judge over a core script's candidates,
   and `judging-ci-failure` runs only on request. Still seven, or fold either into review?
6. **D5** — own work only, for now?
7. **The eval set** — which issues, and will you label sizing, type and risk for each?
8. **Phase 0's caveat** — branch protection now?
