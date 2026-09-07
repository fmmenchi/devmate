# UI architect's reflection on the devmate programme plan — revision 1

- **Date:** 2026-09-07
- **Reviewer:** a fresh-context agent briefed as a senior front-end / VS Code extension architect
- **Input:** `doc/plan/devmate-programme.md` at revision 1, the spokes, the ADRs, and
  `shared-platform`'s design-system ADRs 0018 and 0023
- **Outcome:** 11 findings, all addressed in revision 2; see the review record at the end of the
  plan.

Verbatim, as delivered.

---

**1. The plan gate as designed will block a process for as long as a human is away — make the run a persisted state machine, not a blocked CLI**

(a) Step 4 is a human gate inside `devmate run <owner/repo> <issue>`, which "→ the run directory, a branch, a draft PR, a report" in one invocation; D6 says the run directory is the interface; nothing says how the CLI *waits*.

(b) If the CLI waits on stdin or on a prompt, three things break at once. A UI cannot answer a TTY prompt through files, so the "thin client that reads the same files" is false at the one step that matters. The process that owns the run is now whoever spawned it — a VS Code extension host child dies on window reload, "Developer: Reload Window", extension update, or quitting the editor, and the run dies with it, mid-step-5 with a half-written worktree. And the same run cannot be answered from a second client (the menu-bar app), because the answer lives in a process's stdin, not on disk. The plan's own observability principle ("nothing about a run lives only in a conversation") is violated by the plan's own gate: the pending question lives only in a blocked process.

(c) Every gate is a state transition on disk, and every CLI invocation is short. `devmate run` advances the run until it either finishes or reaches a gate, then **exits 0** with `status: waiting`, having written `gates/plan.request.json` (what is asked, what was produced, a content hash of `plan.md`). Answering is `devmate answer <run> plan --approve|--reject --reason …` (or the UI writing `gates/plan.response.json` and invoking `devmate resume <run>`). `resume` re-validates the hash, so a plan edited after approval is caught. The run directory then genuinely *is* the interface, because the one thing that was not in it — the pending question and its answer — now is. This is also exactly the resumability the plan already claims ("every step is replayable from its inputs"); a gate is just a step whose input arrives later.

(d) D4 and D6 get one sentence each: a gate is a persisted request/response pair, never an interactive prompt. Phase 3's exit adds "the run can be stopped at the gate, the machine rebooted, and resumed". The flow table's "Produces" column for step 4 becomes `gates/plan.response.json`.

**2. Who owns the process is unspecified, and that — not streaming — is what forces a local service**

(a) D6: "A service comes when a UI needs streaming, as a second interface over the same core."

(b) Streaming does not need a service: an append-only `events.ndjson` in the run directory, tailed by any client, is streaming (finding 3). What a file cannot do is *own a process*. With finding 1 adopted, the remaining question is: when the editor starts a 25-minute step-5 implementation, who is the parent? If the extension host is, closing the window cancels the work (or, with `detached: true`, orphans a process nobody can address). If a terminal is, the extension is a spectator with no handle to cancel. Concurrent runs (two issues at once) multiply the problem: two parents, two lifetimes, one repo. The plan is silent on all of it, and "the UI computes nothing" reads as if it also *runs* nothing, which cannot be true for the first UI.

(c) Decide it explicitly, in two stages. **Stage 1 (Phase 3–4, no daemon):** the CLI is the parent; `run.json` records `pid`, `startedAt`, and a heartbeat the core touches every few seconds; `devmate cancel <run>` signals the pid and the core handles SIGTERM by killing the runner session, marking the step `cancelled`, and leaving the worktree (never deleting on cancel). The extension spawns the CLI as a child and, on deactivation, sends SIGTERM and lets the run sit at `status: interrupted` — resumable via `devmate resume`. Closing the UI mid-run is then a pause, not a loss. Liveness in any client is `pid alive && heartbeat fresh`; otherwise the run shows as *stale*, never as *running*. **Stage 2 (only when a run must outlive every client and be observed by several):** the minimal service is `devmate serve` — one process, a Unix socket at `.devmate/devmate.sock`, NDJSON request/response with five verbs (`list`, `start`, `cancel`, `answer`, `subscribe`), which supervises child runs and writes the *same* run directory. The CLI becomes a client of the socket when it exists and runs inline when it does not, so the command surface never changes. Do not build stage 2 before a menu-bar app exists; do write the five verbs down now, because stage 1's commands must be the same five.

(d) D6 changes its trigger from "streaming" to "process ownership across clients". A `run.json` liveness contract enters the Phase 3 exit. Cancellation semantics (what is cleaned, what is kept) become a line in the flow table.

**3. The runner adapter contract has no event stream, so no UI can show progress without parsing transcripts**

(a) D2: adapter contract "output: artefacts directory, exit status".

(b) A step that runs for twenty minutes and emits nothing until exit is, to a UI, indistinguishable from a hung one. Claude Code headless already emits `--output-format stream-json`; if the adapter swallows it into a transcript file, every UI re-parses a runtime-specific transcript, which is the exact coupling the runner boundary exists to prevent. Adding a stream to an adapter boundary *after* two adapters exist is the expensive retrofit; adding it now is one field.

(c) Add to the adapter contract a third output: a stream of runtime-agnostic events — `session.started`, `tool.invoked {name}`, `file.changed {path}`, `message {text}`, `session.finished {exit}` — that the core appends, with `runId`, `step`, and a monotonic timestamp, to `events.ndjson`. The core adds its own `step.started`, `step.finished`, `gate.opened`, `gate.answered`. One line per event, one `write()` per line, so a tailing client never sees a torn record. The transcript stays as the forensic artefact; the event stream is the presentational one.

(d) D2's contract gains "events (NDJSON, agnostic vocabulary)". Phase 2's "two runtimes by hand" gains "both adapters emit the same event vocabulary" — a cheaper agnosticism test than eyeballing.

**4. "A second UI reads the same files" makes the run directory a public API, which makes the second UI expensive, not cheap**

(a) "It renders `issue.json`, `plan.md`, the findings and `score.json` … A second UI — a menu-bar app, a web page — reads the same files."

(b) Fourteen artefact formats, several of them (`findings/<reviewer>.json`, `plan.json`, `verification.json`) certain to churn through Phases 3–5, become something every UI depends on. Each UI then re-implements the same derivations — which step is current, what is waiting, is the process alive, how many findings at which severity, is the evidence stale — and they drift. "Computes nothing" is only true if the core hands the UI something already computed; raw artefacts are inputs to a computation, not its result. The plan conflates *inspectable* (the run directory should be, for debugging) with *the contract* (it should not be).

(c) The contract is a small query surface and versioned view models: `devmate runs --json` (list with status/liveness/pending gate), `devmate show <run> --json` (one run's view model: steps, gate, findings grouped, score, links), `devmate events <run> --follow` (the NDJSON stream), plus `start`, `answer`, `cancel`. Each JSON carries `schemaVersion`; the schemas live in the core package and are the only thing a UI imports. The run directory stays as it is — the core's own storage and the forensic record — and a UI that opens a raw artefact does so as "open file", not as a data dependency. A second UI then costs six commands and three schemas, and the CLI and the extension cannot disagree about what a run's status is because only one of them computes it.

(d) D6 states the contract as "commands + versioned view models; the run directory is storage". Phase 3's exit adds `show --json` and `events --follow`. Phase 4's "nothing the CLI cannot do" becomes literally testable: the extension may only call those commands.

**5. Most of Phase 4 should not be a webview at all**

(a) Phase 4: "issue list, run, plan gate, findings, score. `@fmmenchi/ui` for the webview."

(b) A webview is the most expensive surface VS Code offers: its own process, CSP, message bus, state restore, theme mapping, accessibility done by hand, and it looks like a web page inside an editor no matter how well the tokens are mapped. Every item in that list has a native VS Code surface that is cheaper, more accessible, keyboard-complete, theme-correct, and already what the user's hands know. Findings are the strongest case: step 8 produces `(file, line, severity, reporters)` — that is a `DiagnosticCollection` (Problems panel, squiggles, severity filter) or a `CommentController` thread anchored on the line, and either one lets the user click through to the code, which a webview list cannot do without re-inventing navigation.

(c) Map it out: issues and runs → `TreeDataProvider` (two views in one container, run nodes carrying status icons and a pending-gate badge); progress → `window.withProgress` in the notification area with its native cancel button wired to `devmate cancel`; the diff → `vscode.diff` on a `devmate:` `TextDocumentContentProvider` (the run's `diff.patch` per file), or simply open the worktree; findings → Diagnostics plus Comments; the plan gate → open `plan.md` in a real editor beside the issue, with a notification holding *Approve / Reject…* and a CodeLens at the top of the file offering the same (amend = edit the file, then *Approve as amended*; the core records the diff — finding 7); CI judgement → notification with actions; score → a status-bar item and a Markdown report. What remains for a webview: possibly a run dashboard once there is enough to dash, and nothing in Phase 4. This also removes the largest testing liability (finding 9).

(d) Phase 4's deliverable is rewritten around native surfaces; "`@fmmenchi/ui` for the webview" moves to a later phase, gated on a concrete screen that a tree view cannot carry. The Argent flow in the Phase 4 exit is replaced (finding 9).

**6. If a webview does come, the token mapping is a complete-theme problem with three concrete failure modes the plan does not see**

(a) "Binding the DS tokens to `--vscode-*` variables is a brand preset; presets live in the consuming app."

(b) The layering is right — a preset is a consumer concern, and `[data-theme]` overriding "EXACTLY every color role" is the DS's own definition — but the DS's preset mechanism assumes a *static, complete, contrast-tested* assignment, and a VS Code preset is none of those. (i) **Completeness by construction, not by test**: a theme is every colour role; a preset that maps 80% of them leaves brand oklch purples on the rest, visible as one wrong button in a dark theme. `tokens.test.ts` cannot check it, because the values are `var(--vscode-…)` references, not literals. (ii) **Silent black**: roles are `@property`-registered with `initial-value: oklch(0 0 0)` as a sentinel (ADR 0018). Not every VS Code theme defines every colour; a missing `--vscode-x` makes the role resolve to the sentinel — black text on black — with no error anywhere. (iii) **Scale mismatch**: the DS is rem-based off a 16px root; a webview's `body` is `--vscode-font-size` (13px) but `html` stays 16px, so every DS control renders ~23% larger than the surrounding workbench. Add high-contrast themes (`vscode-high-contrast`, `-light`), which express state through `--vscode-contrastBorder` rather than fills, and the DS has no vocabulary for them. What survives of the DS after a full mapping is its component *structure and behaviour* — Field, Dialog, Choice — not its look, which is the honest reason to use it. Two things that do fit: React inline `style` and `@floating-ui/dom` set styles through the CSSOM, which CSP does not block, so the CSS-first DS needs no `'unsafe-inline'`; and the DS is container-first, which is right for a 300px sidebar.

(c) The preset is a TypeScript object `Record<ColorRole, { vscode: string; fallback: string }>` from which `vscode-preset.css` is generated, so completeness is a type error and every role reads `var(--vscode-x, <fallback>)`; the fallback defeats the sentinel. Set `html { font-size: var(--vscode-font-size) }` in the preset, or map the type-scale tokens explicitly — decide, and test at 13px. Key the preset on `body[data-vscode-theme-kind]` for the four kinds, with HC kinds mapping border roles to `--vscode-contrastBorder`. Fonts: `--vscode-font-family` and `--vscode-editor-font-family` for the two families; no `@font-face` (the DS ships none, which is why it travels). CSP is the standard `default-src 'none'; style-src ${cspSource}; script-src 'nonce-…'; font-src ${cspSource}; img-src ${cspSource} https:` — with `localResourceRoots` covering the DS `dist/` so `@import`s inside `style.css` resolve. And weigh, once, whether the DS earns its place at all against `@vscode-elements/elements` (the successor to the deprecated `@vscode/webview-ui-toolkit`), which looks native for free; the DS wins only if the same webview is meant to ship elsewhere as a web page.

(d) "The VS Code theme mapping is a consumer concern" gains: "generated from a typed, complete role map with fallbacks; not contrast-tested; HC kinds handled". A sentence records the DS-versus-vscode-elements decision and its criterion.

**7. The gates are under-specified as interactions, and the plan has two more gates than D4 admits**

(a) D4: "Plan and merge." Step 4: "approve / amend / reject". Step 13: "no automatic action". Step 9: "bounded number of rounds".

(b) *Amend* has no semantics: free-text note, edited plan, or re-plan with feedback? Each is a different UI and a different core path. *Reject* has no consequence: end the run, or re-triage? The plan's own eval metric ("did the human approve it unchanged?") needs a content hash of what was shown and what was approved, and nothing records it. Then the implicit gates: step 13 judges a CI failure and does nothing — so a human must choose *re-run / start a fix round / dismiss*, which is a third gate; step 9 exhausts its rounds with findings still open — a fourth (what happens to the run?); step 12 opens a *draft* PR below the threshold — who marks it ready, and does the score update after CI? These are all human interactions the UI has to render, and none has an owner in the flow table.

(c) Define each gate as a request with a fixed option set and a typed response, so that every UI renders it from data. Plan: `approve` (records `sha256(plan.md)`), `approve-amended` (the human edited `plan.md` in place; core stores the original as `plan.original.md` and the diff — that diff *is* the eval signal), `reject {reason}` (ends the run; a re-plan is a new run from the same issue with the reason as input, keeping runs immutable). CI: `judgement` produces a gate with `rerun / fix / dismiss`. Rounds exhausted: a gate with `ship-as-draft / abandon`. Draft→ready: `devmate ready <run>` or simply "the human does it on GitHub" — say which. Minimal good interaction in the editor: one notification per pending gate with its options as buttons, a persistent badge on the runs view, and a keyboard command `devmate: answer pending gate` that opens the relevant artefact beside the options. No timeouts; a run waits.

(d) D4 becomes "plan and merge are the *designed* gates; CI-judgement, rounds-exhausted and draft-promotion are *exception* gates with fixed option sets". The flow table gains a row per exception gate with "human" as owner.

**8. Error and partial states are the UI's normal state, and the plan only describes the happy path**

(a) The flow table, phases and exits all describe a run that completes.

(b) A run directory is by design allowed to be partial — a missing reviewer file *is* the signal — so every UI must render a run with absent, stale or malformed artefacts and say what is missing, not crash or show "clean". Add: runner crash mid-step, GitHub auth expiry mid-run (intake works, PR creation fails twenty minutes later), rate limits, a worktree left behind, a run whose pid is dead but whose status says `running`, two runs on the same issue, and the workspace-mapping problem — `.devmate/runs/` lives in which checkout when step 5 runs in an isolated worktree, and which of a multi-root workspace's folders is "the repo"?

(c) The view model (finding 4) carries an explicit per-step state machine — `pending / running / waiting / done / failed / stale / not-measured` — and a per-run `health` computed once by the core from pid, heartbeat and artefact presence. The extension renders those states and nothing else. GitHub auth flows through `vscode.authentication.getSession('github', …)` and is passed to the CLI as an env token, so the extension owns re-auth and the core never prompts. `.devmate/runs/` is anchored at the main checkout (`git rev-parse --git-common-dir`), never in a worktree, and the extension maps each workspace folder to its common dir.

(d) A "Failure states" subsection under Debugging and observability listing the states above; the Phase 3 exit adds "a killed run resumes; a dead-pid run shows as stale".

**9. The testing strategy — an Argent flow over a live run — tests the wrong thing at the wrong cost**

(a) "Argent drives an Electron or VS Code webview through CDP; a saved flow replays the plan-gate interaction on every change." Phase 4 exit: "an Argent flow that replays it."

(b) A real run takes minutes and spends tokens; a flow that replays the plan gate against a real run is neither fast nor deterministic, so it will not run "on every change" — it will run until it flakes once and then never. Technically, VS Code needs `--remote-debugging-port`, and a webview is an out-of-process iframe on a `vscode-webview://` origin; whether Argent's DOM walker reaches inside it is unverified in this plan. With finding 5 adopted there is no webview to drive at all, and Argent has nothing to hold onto in a tree view.

(c) Three layers. First, a **replay runner adapter** — `--runner replay <recorded-run-dir>` — that emits a recorded event stream and artefacts with configurable timing and never touches a model. It is simultaneously the second adapter D2 wants as proof of the contract, the fixture for every UI test, and the way the plan gate can be reached in two seconds. Second, extension-host tests with `@vscode/test-cli` driving commands against the replay runner, asserting tree contents, diagnostics and gate answers landing in the run directory. Third, if a webview ever exists, its React is tested standalone in Vitest browser mode (which the DS already uses) with a fake `acquireVsCodeApi`. Argent remains as a manual smoke on a real window, and the CDP-into-webview question gets a one-hour spike before anything depends on it.

(d) The Debugging and observability bullet is rewritten; D2 gains "the replay adapter is the first second adapter"; Phase 4's exit becomes "the Phase 3 run, triggered from the editor, with the gate answered there — and an extension test that does the same against the replay runner".

**10. Distribution and version skew between extension and core are unaddressed**

(a) "An extension over the same command."

(b) If the extension shells out to whatever `devmate` is on `PATH`, the JSON it parses comes from a version it did not ship with; if it bundles the core as a library and calls it in-process, "CLI first" quietly gets a second entry point that behaves differently (cwd, env, signals). Under VS Code Remote or dev containers the extension host is on the remote machine, which is where the CLI, git, `gh` auth and the runner must be; an extension declared as `ui` kind will spawn on the wrong machine.

(c) The extension bundles the core's CLI binary at the matching version and always spawns it — one entry point, no skew — and additionally accepts a configured path for development. `extensionKind: ["workspace"]`. Every `--json` output carries `schemaVersion`, and the extension refuses (with a message, not a crash) a major it does not know.

(d) One line in Phase 4: "the extension ships its own core; `extensionKind: workspace`".

**11. Accessibility is free on native surfaces and fully manual in a webview — the plan should choose knowing that**

(a) Nothing in the plan mentions accessibility, keyboard operation, or high-contrast.

(b) Tree views, notifications, Problems and the diff editor are screen-reader and keyboard complete by construction. A webview is a blank page: focus management on open and on gate answer, `aria-live` for step progress, roving focus in lists, and HC themes are all hand-written, and the DS's axe tests do not exercise the VS Code preset. This is a second, independent reason for finding 5, and a real cost line for finding 6.

(c) If a webview is built: a single `role="region"` with an `aria-live="polite"` status line for step transitions, focus moved to the gate's first action when it opens and back to the tree on answer, and an HC test in the DS preset's CI. Otherwise: nothing to do, which is the point.

(d) Phase 4 gains "keyboard-only operation of the whole loop" as part of its exit.
