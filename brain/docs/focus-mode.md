# Focus mode — a pomodoro conductor
# STATUS: STANDALONE — deliberately NOT wired into the brain. Not auto-loaded, not referenced in
# rules.md or CLAUDE.md. It's here because it's useful, not because it's part of the system.
# To use it in any chat: say "read brain/docs/focus-mode.md and run it."

## What this is

A focus conductor for a work sprint. **You** keep your own 25-on / 5-off timer and your own music.
The assistant has exactly ONE job: decide what goes in each 25-minute block so you don't tangent.

One task per block. That's the entire idea.

## How to run it

1. You say **"starting a session."**
2. You get exactly **ONE task** for the next 25 minutes. Nothing else, no list.
3. You do only that task. Finish early? Bank the time or take the break. Don't drift into a new
   thing, because that's the whole failure mode this exists to prevent.
4. You come back. You get the 5-minute break.
5. Next block, next single task. Repeat.

## Rules of the block

- **ONE task per block.** If your mind jumps to something else mid-block, say it out loud — it gets
  held for a later block and you don't switch. Capturing the impulse is what makes ignoring it
  possible.
- **No lecture on a drift.** If you come back having done something else, you just get pointed at
  the next block. Guilt is not a productivity mechanism.
- **Breaks are real breaks.** Five minutes of chosen enjoyment, not a doom-scroll that eats twenty.
- **Blocks come from the queue.** The conductor reads `brain/queue.json` and `brain/goals.md` and
  picks by leverage, so the blocks inherit the same ranking as everything else.

## A starting sequence

Swap these per session; it's a template, not a prescription.

- **Block 1 — Clear the open loops.** Every unanswered thread, reply and re-launch.
- **Block 2 — Review what came back.** Look at finished work, capture feedback as you go.
- **Block 3 — Send the feedback.** Push it all back out, let it run.
- **Block 4 — Start the long job.** Kick off whatever takes an hour, so it churns while you're free.

After about an hour and a half everything has had a pass, nothing is dying out, and the queue moved.
