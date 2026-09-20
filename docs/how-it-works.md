# How it works
# STATUS: CANONICAL

Eight mechanisms. Each one exists because something specific went wrong, and each is listed with
the failure that caused it, because a rule without its incident is just an opinion.

---

## 1. The bootstrap is thin on purpose

`CLAUDE.md` is 55 lines and holds **zero live data**. Its entire job is naming the four files to
read at session start.

**The failure it prevents:** a bootstrap file that holds live facts (your current priority, your
project table) has to be edited constantly, and it auto-loads into every session, so a bad edit
poisons every future chat at once. Splitting "instructions that never change" from "facts that
change daily" means the auto-loaded file can sit untouched for months.

That's why editing `CLAUDE.md` is the one operation in the system with a mandatory backup step.

## 2. The core is four capped files

`brain-state.md` (live) · `goals.md` (ranking) · `rules.md` (constitution) · `facts-core.md`
(anti-fabrication).

**The failure it prevents:** an unbounded brain spends its entire context budget booting up. The
predecessor of `brain-state.md` reached 1,044 lines before it was capped, and it's still in
`history/` as the exhibit. At that size, session startup was the most expensive operation of the
day and it produced nothing.

150 lines / 12KB for state. 50 content lines for facts, where **adding one means cutting one** —
that constraint is the feature, because it forces the list to stay the things that actually matter.

## 3. One queue, and every ask becomes a row

`brain/queue.json` = `{_meta, items[]}`. Types: `task`, `idea`, `decision`, `reference`, `bug`.

**The failure it prevents:** things people say they'll track, then don't. The rule is blunt on
purpose: **"noted" without a row means not noted.** No prose notes in the state file, no "I'll
remember that."

Two design details worth stealing:

- **Ideas park by default.** An idea graduates only by out-ranking active work at the weekly review,
  or by being tiny AND unblocking something now. Without that default, every impulse becomes a
  commitment and the queue becomes a wish list.
- **`id` is the only safe identifier.** The `code` field (`PREFIX-N`) is a display label. A code
  freed by a clobber gets re-issued to an unrelated row, and then two rows share it. That happened.

`_meta` documents the file's own contract inline, so anything reading the file learns the rules
from the file.

## 4. Caps plus rotation, never deletion

State overflows to `history/decisions-YYYY-MM.md`. Closed queue rows rotate to
`history/queue-closed-YYYY-MM.json`.

**Rotation fires at 90% of cap, not on a schedule.** This matters more than it sounds. A rotation
ritual performed every session is upkeep, and upkeep is the single thing this system exists to
avoid. Rotating on pressure means most sessions touch nothing.

Deletion was never on the table: the reasoning behind a decision six weeks ago is precisely what
you want when the same question returns. So overflow moves sideways, out of the auto-load path but
still on disk.

Corollary: **a row is a pointer, not an archive.** Long reasoning goes in
`decisions-YYYY-MM.md`, and the row ends with `FULL REASONING: <path> §<date>`.

## 5. `brain-guard.sh` — the pre-commit hook

`.git/hooks/pre-commit` is a three-line shim; the logic lives versioned at
`brain/tools/brain-guard.sh` so it's reviewable and diffable.

Six checks:

1. **Credentials block.** `credentials.md` can never be staged, even with `git add -f`.
2. **State caps.** 150 lines / 12KB, with the rotation instruction in the error message.
3. **Queue schema.** Valid `{_meta, items}`, every row has `id`/`type`/`status`, ids unique, and
   `_meta.count` equals the real row count. The dashboard writes this file and has no idea the
   contract exists, so something has to check.
4. **Mass-erase guard.** Rows are never deleted in normal work: a "kill" keeps the row with
   `status: killed`. Only rotation removes ids, and a rotation stages a `queue-closed-*.json` in
   the same commit. So a staged queue dropping more than 10 ids with no rotation file is a stale
   session overwriting from an old snapshot.
   **The failure it prevents:** exactly that, and it's silent. Nothing errors. The rows are just
   gone, along with a whole session's work, and you find out weeks later.
   This check deliberately **fails open** on any error, so a python or git hiccup can never brick a
   legitimate commit.
5. **Secret-shape scan and a 5MB file cap.**
6. **The tree.** The root has four kinds and nothing else (`brain/`, `projects/`, `dashboard/`,
   `_trash/`); every project folder must carry a `context.md`; `brain/` root holds only the files
   that load at session start, with everything else in `docs/`, `history/`, `routines/` or
   `tools/`.
   **The failure it prevents:** a layout that is true the week you write it down and false three
   months later, once four parallel sessions have each invented somewhere to put a file. By then
   there are four places to look for one thing and no way back without a migration.

**Why a hook and not a rule:** the rules file already said all of this. The rules file is read once,
at boot, and buried by turn forty. The hook runs on every commit with zero memory required.

## 6. `reply-brevity.sh` — the `UserPromptSubmit` hook

Nine lines of `cat`, and the highest-leverage file in the repo.

**The failure it prevents:** a reply-format rule written in seven different markdown files, all of
which faded mid-session, every time. The rule wasn't missing. It was too far away.

A `UserPromptSubmit` hook fires on every message, so the contract arrives adjacent to the newest
turn. Identical words, completely different outcome. Keep it a soft constraint with an escape hatch:
a hard "three bullets max" clips the answers that genuinely needed room, which is worse than no rule.

This is the clearest instance of the general lesson in §9.

## 7. `rabbit-gate.sh` — the second `UserPromptSubmit` hook

The promise this repo makes on its first line is that it catches you rabbit-holing. For a long time
that promise was backed by a paragraph in `rules.md` saying to call drift out loud "when you're
sure," which is the softest possible instruction: every long session reads it as permission to let
it slide. This file is what actually enforces it.

It fires on every message and does three things:

1. **Names your live #1**, read fresh from `brain/your-move.md` or the top of `brain/goals.md`. The
   model never has to remember what you're supposed to be doing, because it's in the current turn.
2. **Requires a verdict before any work** — `Gate: SHIP`, `Gate: UPKEEP`, or `Gate: RABBIT`. Not a
   judgment call about whether to mention drift, a line it has to type either way.
3. **Trips on your own phrasing.** "real quick", "just this one", "while I'm here", "not a rabbit
   hole but". The pattern those share is a defense raised before anyone objected, which is the most
   reliable tell there is that you already know.

`RABBIT` means the ask becomes a queue row and nothing else happens until you type `override`. The
override word is a word you have to type on purpose: "yes" and "go ahead" are reflexes, and a gate
you can pass by reflex is not a gate.

**The failure it prevents:** the three-hour detour that felt reasonable at every individual step,
with an AI that watched the whole thing and said nothing because the rule had scrolled out of reach.

## 8. No cron. Watermarks plus session boundaries.

`routines/config.json` stores `last_review` and `cadence_days`. The session-start read checks it and
surfaces a one-line nudge when it's due.

**Why not an actual scheduler:** a cloud cron only sees last-pushed state, so it forces you to push
constantly to keep it accurate, which is upkeep with extra steps. A local cron fires when the laptop
is shut. The session boundary is the one moment when the state is guaranteed fresh and you are
guaranteed present, so that's where the work happens.

This is how a manual weekly ritual gets remembered with zero scheduling infrastructure.

## 9. Mechanisms over prose

The meta-rule, and the thesis of the whole repo.

**Prose relapses. Hooks hold.**

When the same friction shows up twice, the fix is not another paragraph in `rules.md`. Name the root
cause in one line, then write the smallest durable fix into exactly one home, ranked by how well it
holds: a hook or script, then a schema check or cap, then a routine spec, and only last a rule.

The test: **if everyone forgot this rule tomorrow, would it still work?** If yes, it's a mechanism.
If no, you wrote a reminder and called it a fix.

---

## Also in here, and worth knowing about

**Per-task-type autonomy.** Not one blanket setting. A 12-row table in `rules.md` §5 mapping task
type to default behavior. Reversible edits inside `brain/` are automatic. Deploys are confirm and
batch. Destructive or outward-facing is always confirm. And one that's easy to miss: **when the user
asks a question in their message, answer it and stop** — no execution in the same turn.

**Anti-rabbit-hole, with a mechanical tripwire.** The judgment version is "name the drift off a
top-3 goal." The mechanical version needs no judgment at all: *the session is doing project work
while the declared #1 move is something else → say so in the same turn, every time.* Proceeding is
fine. Going silent is not.

Plus the escalation that makes it real: if you would *recommend* retiring the session, that
recommendation **is** the trigger. Sync and retire it, don't ask. The user should never be the one
who has to pull that trigger.

**Bounded self-improvement.** Propose-only, scored against goals, surfaced weekly, default "not
now." The elegant part is that "near-zero-upkeep" and "self-improving" turn out not to be in
conflict, because the rabbit-hole governor and the improvement engine are the same mechanism: the
score.
