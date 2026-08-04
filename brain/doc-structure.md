# Project and doc structure — guideline
# STATUS: ACTIVE
# Pulled on demand. The one-line rule lives in rules.md §9; this is the detail.

Purpose: stop doc sprawl. A fresh session must be able to tell, in seconds, what a project is and
which document is the live one, without guessing from filenames and dates.

## Per project

- Each project has ONE `context.md`: the **central map**. What it is, which folder holds what, and
  a **Docs Index** table listing every doc with a STATUS and a one-liner, active on top. This is the
  single "start here."
- If a project spans multiple folders, the central `context.md` lives in the primary one and the
  others get a one-line pointer at the top: `> Canonical map: <path>/context.md`.

## Every doc header carries

```
# STATUS: ACTIVE | CANONICAL | SOURCE OF TRUTH | SHIPPED | REFERENCE | ARCHIVED | SUPERSEDED-BY <path>
# Created: YYYY-MM-DD · Updated: YYYY-MM-DD
```

Dates flag staleness, STATUS flags relevance. The Docs Index is the ordering authority, so no
ranking numbers are needed.

## Creating a doc (the rule)

1. Check the project's `context.md` Docs Index first.
2. If an existing doc covers it, **extend that doc.** Don't spawn a new one.
3. Only if it's genuinely new: create it, AND immediately (a) register it in the Docs Index with a
   status, (b) mark anything it supersedes as `SUPERSEDED-BY`. Never drop an unregistered doc in a
   folder. That is precisely the confusion this prevents.

Two corollaries worth their own lines:

- **Update the doc live as decisions land.** Batching doc updates for later means they don't happen,
  and the doc quietly becomes fiction.
- **Don't spin up a doc for a small checklist.** A message or a queue row is enough. Not everything
  deserves a file.

## Ask first (behavioral)

When a session's focus is ambiguous, looks stale, or starts on a new topic without saying which doc
or project it belongs to: **ask one sentence** before digging or editing. *"Quick check, what are we
working on?"* A wrong-doc edit costs far more than a one-line question.
