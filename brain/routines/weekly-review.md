# Routine: weekly review
# STATUS: ACTIVE
# Trigger: "run the weekly review", or the due-nudge from brain/routines/config.json
# Writes: brain/queue.json, brain/goals.md (only if the user re-ranks), routines/config.json

The one recurring ritual in the system. It exists because ideas accumulate faster than they get
resolved, and a list nobody ever prunes stops being a list and becomes a graveyard.

## What it does

A ranking pass over everything parked. Four outcomes per row, and only four:

| Outcome | When | Action |
|---|---|---|
| **Promote** | It out-ranks something currently active | `status: promoted`, becomes a task |
| **Kill** | It hasn't earned attention in weeks and won't | `status: killed`. Keep the row |
| **Hold** | Still genuinely interesting, still not now | Leave it parked |
| **Force-close** | A `decision` row is past its `expires` date | `status: expired` |

## The guardrail that makes it work

**Be stingy.** If nothing out-ranks the current #1 move, promote nothing. That is the system
working, not the review failing. A weekly review that always promotes something is just a slower
way of saying yes to everything.

Killing is the point. A parked idea that survives four reviews untouched is telling you something,
and the honest response is `status: killed`, not a fifth hold. The row stays in the file, so nothing
is lost and you can always resurrect it.

## Steps

1. Re-read `brain/goals.md`. Everything below is scored against it, so if the goals have drifted,
   fix them first and say so.
2. Pull all rows with `type: idea, status: parked` and all rows with `type: decision, status: open`.
3. For each, one line: what it is, and which goal it serves. If it serves none, that's a kill.
4. Score against the CURRENT #1 move, not against the other parked ideas. The comparison that
   matters is "better than what I'm doing now," not "better than the other things I'm not doing."
5. Apply the four outcomes. Set `verified_by` where a row is being closed because something shipped.
6. Check the row count. If the queue is at 90% of its 250-row cap, rotate closed rows dated before
   this month into `brain/history/queue-closed-YYYY-MM.json`, and stage both files in the same
   commit (`brain-guard.sh` needs to see the rotation file to distinguish this from a mass erase).
7. Stamp `weekly_review.last_review` in `brain/routines/config.json` with today's date, and write a
   one-line `last_run_summary`.
8. Report: how many promoted, killed, held, expired. One line each for the promotions. Nothing else.

## What this routine must not do

- Re-rank `goals.md` on its own. Propose, then let the user decide.
- Promote more than the user can actually start. Review bandwidth is the constraint, not compute.
- Turn into a status report. This is a pruning pass, not a recap of the week.
