# Adversarial review of the devmate programme plan — revision 1

- **Date:** 2026-09-07
- **Reviewer:** a fresh-context agent that had not seen the reasoning behind the plan
- **Input:** `doc/plan/devmate-programme.md` at revision 1, plus the spokes, the ADRs and
  `check-skills.sh`
- **Outcome:** 15 findings, 14 CONFIRMED from the text, 1 PLAUSIBLE. All addressed in revision 2;
  see the review record at the end of the plan.

Verbatim, as delivered.

---

**1. Step 11 cannot use the forensic adapter D3 says to build first, because the PR does not exist yet.**
Anchor: D3 "forensic (B) reads CI, diff, commits; live (A) re-runs the gate … **B first, A kept open**"; flow step 11 "Score" precedes step 12 "Pull request" and step 13 "CI watch".
Scenario: run reaches step 11; adapter B looks for CI results → none, since CI runs on the PR opened at step 12 → every CI-anchored criterion is *not measured*; the only evidence available is `verification.json` from step 6, which was produced by *re-running the gate* — i.e. adapter A. The flow builds A at step 6 and calls it B at step 11. Either the score is empty at PR time (and "opened as draft when score is below PR-ready" fires on every run), or A is built in Phase 3 and D3's "B first" is false.
Verdict: CONFIRMED.
Fix: either move Score after CI watch (11 ↔ 13, score the PR post-CI) or state that step 6 *is* adapter A and D3's ordering is A-at-step-6, B-for-re-scoring-later.

---

**2. The "skills never know the tracker" rule is broken by two of the seven skills and by the dependency direction of the consolidation script.**
Anchor: table "Skills … **never** the tracker"; step 2 consumes `issue.json: title, body, labels, linked PRs, comments`; step 13 `judging-ci-failure` "reads logs, decides one bit"; step 8 "a script inside `reviewing-adversarially/scripts/`" that counts against "the roster written to disk *before* launch" by core.
Scenario: swap GitHub for GitLab. `issue.json` has "linked PRs" and CI "checks" — GitHub's data model laundered through a JSON schema devmate owns. `judging-ci-failure`'s three evals are GitHub Actions logs (runner timeouts, rate limits, `actions/cache` misses); on GitLab CI the skill's calibration is meaningless. Meanwhile `consolidate` lives in ai-skills but reads a roster file whose format and location (`.devmate/runs/<id>/`) are devmate's — a skill artefact now depends on devmate, inverting "skills depend on nothing". Phase 2's exit tests *runtime* agnosticism only; nothing ever tests *tracker* agnosticism.
Verdict: CONFIRMED.
Fix: make the honest claim — skills know devmate-owned schemas, not the API — and move roster accounting + consolidation into devmate core (the plan already lists them there under "Debugging and observability", contradicting step 8's location).

---

**3. D1's "fourth door" does not reconcile with the admission criterion; it fails gate 2 outright and the plan itself concedes it.**
Anchor: README gate 2 "would not change in the same pull request as a code change"; authoring.md "Fixed — something downstream parses it. Give the literal template"; architecture.md "Admission — **settled, don't relitigate**"; D1 "gains a fourth door — *a capability the programme needs*".
Scenario: devmate changes `findings.json` grouping or adds a field to `triage.json` (`effort tier` → `effort_tier`, or a new `blocked_by`). The consuming script in devmate and the emitting template in `reviewing-adversarially/SKILL.md` must change in the same PR — that is gate 2's exact test, failed. "Rule of three" is an empirical bar ("explained the same thing three times"); "a capability the programme needs" is design intent. Replacing an observation with an intention is the rationalisation. README already names where these belong: "project-scoped skills in the project".
Verdict: CONFIRMED.
Fix: `devmate/skills/` for the seven (project-scoped, still Agent Skills format, still tool-agnostic); D1 becomes "ai-skills stays craft-only" and architecture.md's "settled" line survives.

---

**4. The runner contract cannot express the flow it is supposed to carry.**
Anchor: D2 "input: repo, issue, skill set, effort; output: artefacts directory, exit status".
Scenario: (a) Plan gate at step 4 — a single invocation with "exit status" has no *paused-for-human* state, so either the CLI blocks on stdin (unusable from the extension under D6) or invocation is per-step, in which case the input is (run dir, step), not (repo, issue). (b) D7 routes *model* per step; the contract carries effort only. (c) Step 7 needs N sessions with guaranteed fresh context; there is no session/context parameter — if the skill spawns the reviewers, it names a vendor primitive (`check-skills.sh` warns on exactly `isolation: worktree`), if core does, the contract needs it. (d) Step 5 "a branch in an isolated worktree" — if the runtime creates it, known-issues.md already records that the harness names it `worktree-feat+…` which the branch gate rejects. (e) Codex: no effort semantics matching Claude's, no subagent primitive, so "fresh context ×N" becomes N processes core must launch — the second adapter "proving" the contract will instead force a rewrite of it.
Verdict: CONFIRMED.
Fix: contract = (run dir, step, skill, model, effort, cwd) → (artefact paths, exit, transcript); one invocation per step; worktrees, parallelism and gates owned by core, never by the runtime.

---

**5. "Every step is replayable from its inputs" is true of two steps out of fourteen.**
Anchor: "Every step is replayable from its inputs. Step 7 re-runs from `plan.json` and the diff" and "every hand-off is inspectable, every step is replayable".
Scenario: re-run step 7 from the same `plan.json` + diff → different findings (sampling; model version bumped since). Re-run step 1 → different `issue.json` (a comment was added). Re-run step 5 → different base, since no step records the base SHA the plan was made against. Re-run step 13 → CI flaked the other way. Only 8 and 11 replay. The run directory also never records model id/version, so the Phase 5 "history" cannot be attributed to a model.
Verdict: CONFIRMED.
Fix: "every *script* step is replayable; every *skill* step is re-runnable with its transcript kept"; add a `manifest.json` with base SHA, model ids, adapter version.

---

**6. The scoring rules produce nonsense on the common case and are gameable by the verify skill.**
Anchor: "absent evidence yields *not measured*, never zero"; "opened as draft when score is below PR-ready"; "`verification.json` carries timestamps; the score refuses anything stale"; step 6 "Who: skill + script".
Scenario A: a repo with no test suite (several of Fabio's own, likely) → every criterion *not measured* → score is arithmetic over an empty set; is that above or below "PR-ready"? Undefined. Scenario B: since *not measured* is never penalised, the verify skill that runs *fewer* commands scores no worse than the one that runs all — the incentive runs the wrong way. Scenario C: timestamps are written by the skill's session; a model that writes `now()` after the last edit satisfies "fresh" without running anything — freshness must be established by core (commit SHA of the diff at verification time), not by a field the model fills. Scenario D: fix loop 9 → 6 re-edits the diff, but `findings/*.json` from step 7 describe the *previous* diff and are never refreshed; step 11 scores stale findings against a new diff — the very thing "fresh evidence or no claim" forbids, applied inconsistently.
Verdict: CONFIRMED.
Fix: score reports coverage (measured/total) and refuses PR-ready under a floor; core stamps the diff SHA into `verification.json`; loop is 6→7→8→9→6 (re-review), not 9→6 alone.

---

**7. The fix loop and blast-radius step have no defined control flow, and the Phase 3 exit forbids the only escape.**
Anchor: step 9 "loops to 6; bounded number of rounds"; step 10 "after a fix round"; Phase 3 exit "no manual step between the plan approval and the PR".
Scenario: rounds exhausted with a critical finding open → the plan gives no branch. If the PR opens anyway, a known-critical PR is opened "as draft" and the score is the only signal — but see #1, the score at that point is mostly *not measured*. If the run stops, that is a manual step between gate and PR, which the exit forbids. Separately: step 10 finds stale docs → they must be edited → that is an edit after step 6's verification → verification is stale by the plan's own rule → must re-run 6 → the table has no arrow from 10 back to 6/9.
Verdict: CONFIRMED.
Fix: write the loop explicitly: `6→7→8→(9→6)* → 10 → (9→6)¹ → 11`, and name the terminal state "blocked with open findings" as a legitimate run outcome with its own artefact.

---

**8. The per-step eval measures are mostly uncomputable on the eval set as described, and one is circular.**
Anchor: "Plan: did the human approve it unchanged? … Review: findings later confirmed real ÷ findings raised. Score: correlation with whether the PR came back"; "Run the matrix: each candidate model × each step, at two effort levels".
Scenario: 8 issues × 4 models × 2 efforts × the plan step = 64 plan approvals by Fabio, by hand, to compute "approved unchanged". "Findings confirmed real" requires a human adjudication per finding per cell — and *which diff* is reviewed? If the agent's own implementation, review quality is confounded by which implement-model produced the diff, so the matrix is not separable per step as step 4 of the method claims. "Correlation with whether the PR came back" needs Phase 5 data on PRs that devmate opened; with 5–10 PRs no correlation is distinguishable from noise, and Phase 5's thresholds are set from those same scores. "Triage: agreement with the human's sizing" needs a hand-labelled sizing per eval issue that Phase 1's exit ("chosen and written down") does not require.
Verdict: CONFIRMED.
Fix: fixed inputs per step (review the *reference* PR's diff; implement from the *reference* plan), a labelled `sizing` field in the eval set, and replace "approved unchanged" with file-set overlap against the reference PR.

---

**9. The literature section misquotes the 15× figure and misapplies FrugalGPT; "triage is the router" ignores that a cheap router's error is paid at implementation price.**
Anchor: "orchestrator plus parallel subagents wins … at roughly **15× the tokens** of a single session"; "*FrugalGPT* … cascades — try cheap first, escalate on low confidence. Here, **triage is the router**"; starting table "triage: small, fast … the cost of a wrong call is one re-triage".
Scenario: Anthropic's post says agents use ~4× the tokens of a *chat* and multi-agent ~15× of a *chat* — so multi- vs single-agent is ~4×, not 15×; the plan overstates by ~4×. FrugalGPT's cascade scores the cheap model's *output* with a trained scorer and escalates on that; it does not route on the query's self-reported confidence, which is what `triage.json` is. A small model that labels a hard issue "simple, high confidence" sends implement to mid-tier; the cost is a wasted implementation — the plan's own words for a wrong plan — not "one re-triage", and nothing downstream catches it until review. RouteLLM's router is trained on preference data with a held-out threshold; nothing in the plan trains anything, so citing it supports "route" only in the loosest sense.
Verdict: CONFIRMED (15×, FrugalGPT); the compounding claim follows from the starting table.
Fix: correct the figure; drop FrugalGPT or use it honestly (escalate when the *verify* step fails, which is an output signal); make triage's confidence gate a *floor* — low confidence forces the strong tier, never the cheap one.

---

**10. Phase 0 is factually stale and its exit was met by a route the contract forbids.**
Anchor: "Nine commits on `feat/project-contract`, unpushed; CI has never run. **Exit:** the PR is merged with CI green".
Observed: `origin/main` is `d27f151 Merge branch 'feat/project-contract'`; three merge commits on main; `gh pr list --state all` returns nothing; CI ran green on the pushes to main. AGENTS.md: "Rebase and merge — the history stays linear. No merge commits." The plan's own foundation phase was closed by merge commits without a PR, i.e. the "Always wait for CI" and "rebase" rules were bypassed on the first real exercise of the gates the plan relies on.
Verdict: CONFIRMED.
Fix: rewrite Phase 0 to the actual state and record the merge-commit exception in known-issues.md.

---

**11. Phase 2's exit contradicts D2 and "Deliberately not in the plan", and the "by hand" claim is far more expensive than asserted.**
Anchor: Phase 2 exit "every skill exercised by hand through **two** runtimes"; D2 "Claude Code headless first … the second adapter (Codex) is how the contract is proven"; "Multiple runtimes at once. One first".
Scenario: in Phase 2 no adapter exists. "By hand" means Fabio supplies `issue.json`, a roster, N fresh contexts and a failing CI check manually for each of 7 skills × 3 evals × 2 runtimes = 42 sessions. `reviewing-adversarially` ("fresh context per reviewer") and `judging-ci-failure` (needs a real failing check on a real PR) cannot be exercised by hand in any meaningful way before Phase 3. Codex CLI has no isolated-subagent primitive, so the one portability that matters — "delegate to an isolated subagent" — is untestable there.
Verdict: CONFIRMED.
Fix: Phase 2 exit = `check-skills.sh` green + evals run on Claude Code; agnosticism is proven in Phase 3.5 when adapter #2 exists (which is what D2 already says).

---

**12. "Validated by core" for the plan is undefined and has no failure path.**
Anchor: step 3 "the plan is *validated by core* before it is shown".
Scenario: `plan.md` is prose. The only mechanically checkable content is in `plan.json`: do listed files exist, is `alternatives` non-empty, does it reference the issue. If validation fails, the table has no loop back to step 3 and no terminal state; the human either sees an invalid plan or the run dies silently.
Verdict: CONFIRMED.
Fix: enumerate the checks (schema; every `files[]` path exists or is flagged `new`; ≥1 alternative; issue id matches) and "re-run step 3 once, then stop with `plan.invalid`".

---

**13. Consolidation "by `(file, line)`, highest severity kept" is neither deterministic in effect nor lossless.**
Anchor: step 8 "grouped by `(file, line)`, highest severity kept, reporters listed | deterministic".
Scenario: reviewer A reports an off-by-one at `foo.ts:41`, reviewer B the same defect at `foo.ts:42` (models cite lines approximately) → two findings, no dedupe. Reviewer A reports a *security* issue at `foo.ts:80` (high), reviewer B an unrelated *naming* nit at the same line (low) → merged into one finding, the nit's text lost or the security one's diluted. Architecture-level findings with no `(file, line)` have no key and fall out. The script is deterministic; the grouping rule produces wrong groups.
Verdict: CONFIRMED.
Fix: keep every finding; group by `(file, hunk)` with a `same_defect` explicit field; unlocated findings in their own bucket.

---

**14. Phase 4's exit requires a fixture the plan never creates, and the QA claim overreaches `argent-qa-flows`' own requirements.**
Anchor: Phase 4 exit "an Argent flow that replays it"; "a saved flow replays the plan-gate interaction on every change".
Scenario: `argent-qa-flows` demands "deterministic setup" and "two consecutive full passes". A plan gate driven by a live model run renders a different `plan.md` each run, so the flow's text assertions fail on the second pass. The flow can only replay against a frozen run directory — which is a fixture Phase 3 never commits.
Verdict: PLAUSIBLE (depends on how the flow asserts).
Fix: Phase 3 exit adds "the run directory is committed as `fixtures/run-<issue>/`"; Phase 4's flow reads it.

---

**15. ADR bootstrap circularity and the plan's own placement violate the ADR rule it invokes.**
Anchor: "gets its own ADR — in the repository it concerns — *before* the phase that depends on it"; Phase 1 "`devmate` gets its skeleton and D2, D4, D5, D6 as its first ADRs"; ADR README "Structural decisions for `ai-skills` are recorded here".
Scenario: creating devmate's skeleton is a structural decision in devmate with no ADR possible before it (the repo is empty); D1 relitigates a spoke that says "settled, don't relitigate" without an ADR existing yet; and the plan lives in `ai-skills/doc/plan/` where the ADR README scopes records to ai-skills only, so D2–D7 sit in a repository whose decision log disclaims them.
Verdict: CONFIRMED (minor, but it is the plan's own rule).
Fix: Phase 1 step zero = devmate skeleton with ADR 0001 "this repository exists" as its first commit; D1 gets an ADR in ai-skills *before* the plan's D1 row is treated as a recommendation.
