---
description: Interview me and write my brain — goals, facts, working style, first queue rows
argument-hint: (no arguments)
---

# /setup — build this person's brain

You are setting up a fresh install of northstar-os for the person in this chat. At the end of this,
the placeholder files become theirs and the system starts working.

Read `brain/rules.md` first so you know what you're configuring.

## Before you start

Check whether this brain is already populated: does `brain/goals.md` still contain
`_Not set yet._`, and is `brain/queue.json`'s `items` array empty?

- **Both empty** → fresh install, run the whole interview.
- **Already populated** → say so, and offer three choices: re-run the whole thing (overwrites),
  fill in only the sections that are still placeholders, or stop. **Never silently overwrite a
  populated brain.** Wait for an answer.

## How to run the interview

Conversational, not a form. Ask in small batches, two or three questions at a time, and react to
what they say. Use `AskUserQuestion` where the answer is a pick from options; use plain questions
where it's genuinely open.

Three things that make this good rather than tedious:

1. **Follow up when an answer is vague.** "Get more clients" is not a goal, it's a mood. Ask what
   would have to be true in three months for them to say it worked. One follow-up, not an
   interrogation.
2. **Push back once if the top 3 aren't really three.** Six top priorities means no priorities, and
   the whole ranking system downstream depends on this list being honest. Say it once, then take
   whatever they give you.
3. **Don't over-ask.** If you can infer something reasonable, infer it and say what you assumed.
   The point is that they're set up in a few minutes, not that you collected a complete dataset.

## What to ask, and where each answer lands

**1. Identity → `brain/facts-core.md`**
Their name, what they do, what they're building or working on. Keep it to atomic one-line facts.
Explicitly tell them: no passwords or API keys here — those go in `brain/credentials.md`, which is
gitignored and never committed.

**2. North star → `brain/goals.md`**
What's true in six to twelve months if this period went well? One or two sentences. Push for
something they could tell had actually happened.

**3. Top 3, ranked → `brain/goals.md`**
The three things right now, in order. For each, how they'd know it moved. Explain why the ranking
matters: ties break downward, and "off a top-3 goal" is the definition the rabbit-hole flag uses.
Also capture anything they name as deliberately parked. Writing those down is what stops them
leaking back in as quick wins.

**4. Live projects → `dashboard/data/projects.json`**
For each: name, a short code (2-5 letters, used as a row-id prefix), one-line status, current
phase (active / queue / paused / done), and the next concrete action. Write the JSON with the same
field shape as the seed file already there, and replace the example rows entirely.

**5. Working style → `brain/rules.local.md`**
This one matters more than it sounds, so ask it properly:
- How do they want replies? Length, tone, how blunt.
- Where should the assistant just act, and where must it stop and ask?
- Anything they've had to correct an AI on more than once? That question tends to produce the most
  valuable single line in the whole setup.
- Any house style for writing produced under their name.

**6. Seed the queue → `brain/queue.json`**
Ask: "What's actually on your plate right now? Dump it, unsorted, however it comes out."
Take the dump and classify every item:
- something to do → `type: task`, `status: todo`
- a someday impulse → `type: idea`, `status: parked` (parked by default, always)
- a call only they can make → `type: decision`, `status: open`

Show them the classification before writing, in one compact list. Then write the rows: short
human-slug `id`, `code` as `PREFIX-N` using their project codes, `project_id`, `text`, `created`
as today, `starred: false` except the two or three they name as most important.

**Set `_meta.count` to the real row count.** The pre-commit guard rejects the commit if it's wrong,
and the dashboard writes this file too.

**7. First state → `brain/brain-state.md`**
Fill in the Your Move block with the single highest-leverage action from everything above, plus the
project snapshot table. Respect the 150-line cap. This should be short.

## Then, in order

1. **Install the hook.** Run `bash brain/tools/install.sh`. It links the pre-commit guard, checks
   python3, and deliberately trips the guard so they watch it block a bad commit. Show them that
   output. A guard nobody has seen fire is a guard nobody trusts.
2. **Validate your own work.** `python3 -c "import json; json.load(open('brain/queue.json'))"`, and
   confirm `_meta.count` equals the number of rows. Then confirm every file you claimed to write
   actually exists.
3. **Stamp the routine watermark.** Set `weekly_review.last_review` in
   `brain/routines/config.json` to today, so their first review lands in a week rather than
   immediately.
4. **Commit it.** `git add` the specific files you wrote and commit. If the guard blocks you, fix
   the cause and say what it caught. That's the system working.

## Close

Print, short:
- Every file you wrote, one line each, with what's in it.
- Their #1 move, pulled from the state file you just created.
- Two commands: `python3 serve.py` for the dashboard, and "say `boss` in any new chat" for the
  daily view.

Then stop. Don't start working on their first task in the same turn.
