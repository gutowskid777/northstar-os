# northstar-os — bootstrap for non-Claude agents

This is the same contract as `CLAUDE.md`. It exists so Codex, Cursor, and anything else that reads
`AGENTS.md` gets the identical brief. **If you change one, change both.** A drifted copy is worse
than no copy, because it teaches two different systems two different rules.

---

## At session start, read the brain core

Four files, all size-capped, so the whole read is cheap:

1. `brain/brain-state.md` — live state and today's move (capped at 150 lines)
2. `brain/goals.md` — the ranked anchor; everything is scored against it
3. `brain/rules.md` + `brain/rules.local.md` — the constitution, and the user's working style
4. `brain/facts-core.md` — atomic facts, so nothing about the user gets invented

Don't re-read all of `brain/` per prompt. Pull on demand. **Always re-read state before a write.**

Also check `brain/routines/config.json` → `weekly_review`. If `today - last_review >=
cadence_days`, surface a one-line nudge.

## The rules that will bite you if you skip them

- **Every ask becomes a row in `brain/queue.json` immediately.** Not a note, not a promise. If it
  isn't a row, it didn't happen.
- **Never write `queue.json` whole from memory.** Re-read it and merge by `id`. Losing rows is
  silent: nothing errors, they're just gone.
- **`brain-state.md` is capped at 150 lines / 12KB** and `queue.json` at 250 rows / 300KB. A
  pre-commit hook enforces both. Don't append past a cap; rotate to `brain/history/`.
- **Never hard delete.** Move it to `_trash/`.
- **A branch is not isolation.** Parallel sessions share one working tree. Stage your own paths;
  never `git commit -am`.
- **The user asked a question in their message** → answer it and stop. No execution in the same
  turn.

Full detail is in `brain/rules.md`. Rationale for why each rule exists is in `docs/how-it-works.md`.
