---
description: Reconcile the queue against what this session actually did, then refresh state
argument-hint: (no arguments)
---

# /sync — session-end reconcile

Run the full session-end sync from `brain/rules.md` §1.5. You should normally be doing this on your
own at a natural stop; this command is for forcing it.

1. **Reconcile `brain/queue.json`.** Diff what this session actually did against the open rows.
   Flip statuses, set `verified_by` to a commit hash, file path, or URL. Add rows for anything that
   was asked for and never got one. Re-read the file first and merge by `id` — never write it whole
   from memory.
2. **Refresh `brain/brain-state.md` in place.** Respect the 150-line / 12KB cap. Move superseded
   content to `brain/history/decisions-YYYY-MM.md`. Do not append.
3. **Rotate only under pressure.** If the queue is at 90% of its 250-row cap, move closed rows
   dated before this month to `brain/history/queue-closed-YYYY-MM.json` and stage it in the same
   commit. Below that, leave the file alone.
4. **Refresh Your Move** per `brain/routines/your-move-refresh.md`.
5. **Commit**, staging your own paths explicitly. Never `git commit -am` — another session may be
   live in the same working tree.

Report the result in ONE line: what changed in state. Not the commit, not a recap of the session.
