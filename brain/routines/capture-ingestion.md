# Routine: capture ingestion
# STATUS: OPTIONAL — configure `capture_ingestion.source` in routines/config.json to enable
# Trigger: "ingest my notes", or at session start if the source has changed since last_ingested
# Writes: brain/queue.json, routines/config.json

Turns a raw brain-dump into queue rows without turning it into duplicate queue rows.

## The problem this solves

You capture things away from your desk: a notes app, a voice memo, a text file. Those captures are
worthless unless they land in the queue, and a blind import makes the queue worthless, because
half of what you dumped is already a row and now it's two.

## Steps

1. Read `capture_ingestion.source` and `last_ingested` from `brain/routines/config.json`.
   If `source` is null, this routine is off. Say so and stop.
2. Read the source. Take only content added after `last_ingested`.
3. **Reconcile before writing.** For each captured item, search existing rows for a match — by
   meaning, not by string. A capture that says "fix the signup email" and an existing row that says
   "signup confirmation is going to spam" are the same row.
   - Match found → update the existing row (append to `verbatim`, refresh `next`). Never add.
   - No match → it's new.
4. Classify each new item: `task` (something to do), `idea` (an impulse — parked by default),
   `decision` (a call to make), `reference` (a fact to keep).
5. **Show the plan and confirm before writing.** N new rows, M updates, and the ones you're
   skipping as duplicates, with what they matched. This confirmation is the whole safety of the
   routine — a wrong classification is cheap to fix, a silent duplicate is not.
6. Write the rows. Re-read `queue.json` first and merge by `id` (see rules §8).
7. Advance `last_ingested` to now and write a one-line `last_run_summary`.

## Rules

- **Never blind-import.** The reconcile step is not optional; it's the reason this exists rather
  than a copy-paste.
- **Keep the original words** in `verbatim`. Your phrasing at capture time carries intent that
  gets lost the moment it's paraphrased into a clean task title.
- **Ideas park by default.** A brain dump is a capture, not a commitment. Promotion happens at the
  weekly review.
- **The watermark only advances on success.** A half-finished ingest that advanced the watermark
  silently loses everything in the gap.
