# Routine: grind mode
# STATUS: ACTIVE
# Trigger: "grind mode", or any large parallel push
# Writes: whatever the work writes, plus a run directory of findings

For when you want to spend a large budget on one problem: many agents, one goal, unattended.

## The one rule that matters

**Think once, write the thinking to disk. Apply is a separate, cheap step that reads from disk.**

The failure mode this prevents: a fan-out where each downstream agent's prompt embeds the full
output of the upstream agents. That looks efficient and is catastrophic, because every retry,
every resume, and every follow-up re-pays for the entire accumulated context. A single run
structured that way can burn millions of tokens producing an amount of work a fraction of that
size would have covered.

So: **agents return data, the orchestrator writes files.** Downstream steps read the files. The
orchestrator itself stays thin and never holds the full output of everything it spawned.

## Shape

1. **Scope it first, cheaply.** List the actual work items before spawning anything. You almost
   never know the fan-out width before you look, and guessing it wrong is the expensive mistake.
2. **Fan out, one item per agent.** Each returns structured data, not prose. Each writes its own
   artifact to its own path so nothing collides.
3. **Verify adversarially.** For anything a fan-out *found* (bugs, risks, opportunities), spawn
   independent checkers prompted to REFUTE the finding, not confirm it. A finding that survives a
   genuine attempt to kill it is worth acting on. One that was only ever confirmed is not.
4. **Synthesize from the files**, not from the agents' return values.
5. **Report what got dropped.** If the run capped coverage anywhere — top-N, no retries, sampling —
   say so. Silent truncation reads exactly like complete coverage, and that's how a run gets
   trusted more than it earned.

## Guardrails

- **Review bandwidth is the constraint, not compute.** Never produce more parallel output than can
  actually be reviewed. Twelve unreviewed artifacts are worth less than three read ones.
- **Isolation is real isolation.** Parallel agents editing the same working tree will clobber each
  other. A branch does not fix this; a separate worktree does.
- **Cost gets stated before launch, not after.** Rough agent count and rough spend, up front.
- **Don't launch one out of boredom.** A big fan-out needs a real question. "There's budget left"
  is not one.
