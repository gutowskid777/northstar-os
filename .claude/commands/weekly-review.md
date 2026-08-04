---
description: Rank, promote, kill, or hold everything parked in the queue
argument-hint: (no arguments)
---

# /weekly-review

Execute `brain/routines/weekly-review.md` exactly as written.

The spec is the single source of truth. This command is a pointer, so that the routine can be
edited in one place and never drift from the thing that runs it.

Two reminders, because they're the parts most often skipped:

- **Be stingy.** If nothing out-ranks the current #1 move, promote nothing. That's the system
  working, not the review failing.
- **Stamp the watermark.** Write today's date to `weekly_review.last_review` in
  `brain/routines/config.json` when you're done, or the due-nudge fires again tomorrow.
