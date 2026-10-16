# ADR 0001 — `AGENTS.md` is the only agent contract, indexed by topic

- **Status:** proposed
- **Date:** 2026-10-15
- **Deciders:** Fabio Menchicchi

## Context and problem statement

devmate is built mostly by coding agents. What an agent knows about this repository is what it
reads at startup plus what it chooses to open, and a context window is finite: one long file
is either truncated, skimmed, or paid for on every task that needs a tenth of it. Several tools
read this repository, and they look for different filenames.

## Decision

**`AGENTS.md` is the only agent contract.** No `CLAUDE.md`, not even as a symlink: Claude Code
reads `AGENTS.md` (observed in Fabio's sessions on `ai-skills`, which has no `CLAUDE.md`). A tool
that looks for another name is configured to read `AGENTS.md` — Gemini CLI through
`contextFileName` in `.gemini/settings.json` — and is never served a second file.

**It is a hub, not a manual.** The root `AGENTS.md` carries what every task needs and nothing
else: what devmate is, the commands, the gate, the rules whose breach is silent, and an
**index** of topic spokes, each with a line saying when to open it. A spoke is
`.agents/doc/<topic>.md`, one topic each, opened only when a task touches that topic. Nothing
important lives only in the hub's prose without a spoke behind it, and no spoke exists without
an index line.

**Agent docs and human docs are separate and point at each other.** `.agents/doc/` holds rules
for agents: imperative, terse, about this repository. The documentation site (ADR 0002) holds
explanation for people, ADRs included. A spoke links to the ADR that decided its rule; it states
the rule, it never re-decides it.

**A project that grows its own rules gets its own `AGENTS.md`**, which the root index lists.

## Consequences

- Adding a rule means choosing its spoke, or adding a spoke and its index line in the same
  change. A rule with no home is a rule nobody reads.
- The hub stays short enough to be read whole on every task; that is the measure, not a line
  count.
- `.claude/settings.json`, `.gemini/settings.json`, `.codex/config.toml` and `opencode.json` are
  tracked: they are how each tool is pointed at the same contract and the same Nx tooling.
