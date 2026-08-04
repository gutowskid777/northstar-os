# brain/history/

Nothing in this system is ever deleted. It rotates here.

## What lands here

| File pattern | Rotated from | When |
|---|---|---|
| `decisions-YYYY-MM.md` | `brain-state.md` | When state would exceed 150 lines / 12KB |
| `queue-closed-YYYY-MM.json` | `brain/queue.json` | When the queue hits 90% of its 250-row cap |

## Why rotation instead of deletion

Two different problems, one answer.

The first is cost. `brain-state.md` and `queue.json` are read at the start of every session. Left
alone they grow forever, and the boot read quietly becomes the most expensive thing in the context
window. Caps fix that.

The second is regret. Deleting the overflow would fix the cost and create a worse problem: the
reasoning behind a decision six weeks ago is exactly what you want when the same question comes
back. So the cap pushes old content *sideways* rather than off a cliff. It stops loading
automatically, and it's still there when something references it.

## The rotation contract

- **On pressure, not on a schedule.** Rotating every session is upkeep, and upkeep is the thing
  this system exists to avoid. Rotate at 90% of cap and not before.
- **Closed rows only, dated before the current month.** An open row is live work; it can't rotate no
  matter how old it is. If open rows alone are pushing the cap, the queue needs a kill pass at the
  weekly review, not compression.
- **Rotation stages its history file in the same commit.** `brain-guard.sh` uses that as the signal
  distinguishing a legitimate rotation from a stale session mass-erasing the queue. A commit that
  drops more than 10 row ids without a `queue-closed-*.json` alongside it gets blocked.

## Long reasoning lives here too

A queue row is a pointer, not an archive. When a decision needs paragraphs, they go in
`decisions-YYYY-MM.md` and the row ends with `FULL REASONING: <path> §<date>`. That's what keeps
rows scannable while nothing gets lost.
