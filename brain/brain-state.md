# brain/brain-state.md — live state
# HARD CAP: 150 lines / 12,000 bytes. Enforced by brain/tools/brain-guard.sh on every commit.
# When it would overflow: DON'T append. Move superseded content to brain/history/decisions-YYYY-MM.md.
# STATUS: PLACEHOLDER — run /setup.
#
# Why the cap exists: this file auto-loads at the start of every session. Unbounded, it grows into
# the single most expensive thing you read, and the boot cost quietly eats the context you wanted
# for actual work. The cap is not tidiness. It's what keeps the session-start read cheap forever.

---

## ▶ YOUR MOVE

_Not set yet. Run `/setup`._

## Project snapshot

| Project | Status | Next move |
|---|---|---|
| _none yet_ | | |

## Timeline

<!-- What actually happened, newest first. One line each. When this section pushes the file
     toward the cap, the OLD entries move to brain/history/decisions-YYYY-MM.md. -->

_Nothing yet._

## Standing cautions

<!-- Things that have bitten before and will again. Short. Each one earns its line by having
     actually happened. -->

_Nothing yet._
