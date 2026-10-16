# Fixture issues

Each eval gives the skill one `issue.json` and one `triage.json`, both below. All three are
triaged actionable, not `human`, so the skill fires on each.

## 01 — `jot-12`

```json
{
  "schemaVersion": 1,
  "id": "jot-12",
  "title": "jot list --json",
  "body": "Scripts can't read `jot list`. Add a --json flag that prints the notes as a JSON array instead of one line per note.",
  "labels": ["feature"]
}
```

```json
{
  "schemaVersion": 1,
  "actionable": true,
  "complexity": "simple",
  "confidence": "high",
  "effort": "low",
  "risk": "none"
}
```

## 02 — `jot-15`

```json
{
  "schemaVersion": 1,
  "id": "jot-15",
  "title": "Export to Markdown and import from CSV",
  "body": "I want `jot export notes.md` to write all notes as a Markdown list, and `jot import notes.csv` to add notes from a CSV with a `text` column.",
  "labels": ["feature"]
}
```

```json
{
  "schemaVersion": 1,
  "actionable": true,
  "complexity": "moderate",
  "confidence": "high",
  "effort": "medium",
  "risk": "none"
}
```

## 03 — `jot-21`

```json
{
  "schemaVersion": 1,
  "id": "jot-21",
  "title": "Sync notes between my laptops",
  "body": "Notes I add on one laptop should show up on the other. Edits on both should not lose anything.",
  "labels": ["feature"]
}
```

```json
{
  "schemaVersion": 1,
  "actionable": true,
  "complexity": "complex",
  "confidence": "medium",
  "effort": "high",
  "risk": "none"
}
```
