# Evals — planning-from-an-issue

Three scenarios in which an agent **fails without this skill**. They live here, at the root and
outside the skill directory (ADR 0003): they are tests, and they are not part of what the runner
loads.

Every scenario plans against the same fixture: `fixtures/repo.md`, a six-file notes CLI with a
declared gate, and one issue from `fixtures/issues.md`. A stranger can run each eval with and
without the skill and observe the pass criterion without any other context.

| #                                       | Scenario                                              | Fails without the skill because                                        |
| --------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------- |
| [01](./01-one-change-planned.md)        | A single-behaviour feature                            | the plan has no rejected alternative, writes commands, states no scope |
| [02](./02-two-behaviours-split.md)      | Two independent behaviours in one issue               | one plan swallows both, or the agent opens issues itself               |
| [03](./03-undecided-structure-split.md) | A feature resting on a decision the issue leaves open | the plan takes the decision silently                                   |

Evals 02 and 03 carry a **plannability check**: each proposed issue goes back through the skill
and must come out as `plan`. That is what stops a split from being a way to avoid a hard plan.

**The baselines are predicted, not observed.** Unlike `fresh-context-review`'s, none of these
has been run yet; each baseline describes the failure the plan's design expects, in a form a
stranger can observe. The first run replaces every prediction with what was seen, or records
that the prediction was wrong.
