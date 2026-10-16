# Skills — agent rules

For writing or editing a **pipeline** skill in `skills/`. Decided in ADRs
[0003](../../apps/docusaurus/docs/adr/0003-pipeline-skills-their-evals-and-their-gate.md) and
[0004](../../apps/docusaurus/docs/adr/0004-schemas-are-the-contract.md).

## Shape

- `skills/<name>/SKILL.md` — exactly that casing: the tools are case-sensitive, macOS is not, so
  a `SKILL.MD` installs cleanly and never loads.
- **The `description` is the routing contract.** It names what the skill does, when to use it,
  and when not to.
- A skill knows devmate's **schemas**, never the tracker's API, never a vendor tool name, never
  Node.

## Evals first

`evals/<name>/` holds at least three scenarios, `NN-<kebab>.md`, and their `fixtures/`. Write the
evals **before** the prose. An eval whose expected result was predicted rather than observed says
so.

## Examples are checked

Every JSON example in a `SKILL.md` is fenced as ` ```json <artefact> ` and must validate against
`schemas/<artefact>.schema.json`. An output with two shapes gets two examples. A JSON block that
names no schema fails the gate.

## The gate

`scripts/check-skills.sh` runs `ai-skills`' `check-skills.sh` at the SHA in `.ai-skills-ref`
against this repository, then devmate's schema check. It is part of `pnpm run check`. It fails
closed: if it cannot obtain the pinned gate, it fails — never "skip and pass". To pick up a newer
gate, move `.ai-skills-ref` in its own pull request.
