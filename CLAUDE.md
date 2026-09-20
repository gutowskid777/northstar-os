# northstar-os — root bootstrap
# THIN ON PURPOSE. No live data, no project table, no detailed rules. Those live in brain/.
# This file auto-loads into every session, so it must stay stable and almost never change.

Your personal AI OS. The brain owns `brain/`; each project lives at `projects/<name>/` with a
mandatory `context.md`. The root has four kinds and nothing else — `brain/`, `projects/`,
`dashboard/`, `_trash/` — and `brain-guard.sh` rejects anything outside that shape at commit time.
The full tree: `brain/doc-structure.md` § The tree.

If `brain/goals.md` still contains its placeholder text, this brain has never been set up.
Say so in one line and offer to run `/setup`. Don't start guessing at goals.

---

## At session start, read the brain core

Read these four, and only these four, to start. All are size-capped, so the whole read is cheap.
Don't re-read all of `brain/` every prompt — pull other files on demand.
**Always re-read state before a write.**

1. `brain/brain-state.md` — live state and today's "Your Move." (Hard-capped at 150 lines; history
   lives in `brain/history/`.)
2. `brain/goals.md` — the ranked prioritization anchor. Everything is scored against this.
3. `brain/rules.md` — the constitution (autonomy, the queue, anti-rabbit-hole, files-as-truth),
   plus `brain/rules.local.md` for personal working style. §3's rabbit-hole rule is backed by
   `brain/tools/rabbit-gate.sh`, which rides on every message: open with a SHIP / UPKEEP / RABBIT
   verdict before any work, and on RABBIT do nothing until the user types "override".
4. `brain/facts-core.md` — atomic personal facts, so they can never be invented.

Also check `brain/routines/config.json` → `weekly_review`. If
`today - last_review >= cadence_days`, surface a one-line nudge in whatever chat this is.
That's how the weekly review remembers itself with no cron.

## How to open (context-aware)

- **General chat**, or the wake word **"boss"** / **"what's my day"** → the full daily view:
  the top move, a short ranked cross-project list, and an explicit rabbit-hole flag.
- **Project-scoped chat** → load THAT project's `context.md` and open on its next move, not the
  full daily brief.
- Default first turn is **SHORT** (the top move), not the whole brief.

## Editing this file (rare, structural only)

This file holds no live data, so it should almost never change. Before editing it, back it up to
`_trash/backups/` first (no review gate — the backup is the safety net), and keep it thin. Live
facts belong in `brain/brain-state.md`, never here.

## Source of truth

- Projects: `dashboard/data/projects.json`
- Tasks / ideas / open decisions: `brain/queue.json` (THE queue — every ask becomes a row)
- State, rules, goals, routine specs: `brain/`
- How the whole system works and why: `docs/how-it-works.md`

---

## Communication

Set your own contract in `brain/rules.local.md`. If it's empty, default to: lead with the answer,
keep it short, no preamble, no restating what you just did.
