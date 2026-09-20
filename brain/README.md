# brain/

This is the whole system. Everything else in the repo either reads these files or protects them.

| File | What it is |
|---|---|
| `brain-state.md` | Live state and today's move. **Capped at 150 lines.** Overflow rotates to `history/`. |
| `goals.md` | The ranked anchor. Everything gets scored against this. |
| `rules.md` | The constitution. Generic, safe to update from upstream. |
| `rules.local.md` | Your working style. Yours, never overwritten. |
| `facts-core.md` | Atomic facts, so nothing about you gets invented. Capped at 50 lines. |
| `queue.json` | THE queue. Every task, idea, and open decision. **Capped at 250 rows.** |
| `docs/self-improve.md` | The loop for turning recurring friction into one durable fix. |
| `doc-structure.md` | How docs stay navigable instead of sprawling. |
| `docs/focus-mode.md` | A standalone pomodoro conductor. Not wired into anything. |
| `credentials.md` | **Gitignored. Never committed.** Created by you, if you want it. |
| `history/` | Where rotated state and closed queue rows go. Nothing is ever deleted. |
| `routines/` | Specs for the recurring rituals, plus the watermark file that makes them run with no cron. |
| `tools/` | The scripts that make the rules real. `brain-guard.sh` is the important one. |

## The four files that load at session start

`brain-state.md`, `goals.md`, `rules.md`, `facts-core.md`. That's it, and all four are size-capped
so the read is cheap. Everything else is pulled on demand.

The caps are not tidiness. A brain that grows without limit spends its whole context budget booting
up, and then has nothing left for the work. Rotation is how it stays fast at month twelve.

## The one rule worth internalizing

**Every ask becomes a row in `queue.json` immediately.** Not a note in state, not a line in a chat
you'll scroll back to. If it isn't a row, it didn't happen. Everything else here is downstream of
that.
