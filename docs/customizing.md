# Customizing
# STATUS: ACTIVE

Everything here is a file you own. Nothing is compiled, minified, or hidden behind a package.

---

## Your working style

`brain/rules.local.md`. This is the file to actually invest in.

`rules.md` is generic and gets updated upstream; `rules.local.md` is yours and is never overwritten.
`/setup` seeds it, and after that the best entries come from a single habit: **when you catch
yourself giving the same correction twice, write it down here.** A correction you've given three
times isn't a preference, it's a rule that was missing a home.

## Changing the caps

Three places, and they must agree:

| Cap | Set in |
|---|---|
| State: 150 lines / 12,000 bytes | `brain/tools/brain-guard.sh` check 2 |
| Queue: 250 rows / 300,000 bytes | `brain/tools/brain-guard.sh` check 3b |
| Facts: 50 content lines | `brain/facts-core.md` header, enforced by convention |

Raising a cap is usually the wrong move. The caps exist because the read cost is paid at the start
of every single session, and a bigger cap makes every future session more expensive. If the queue
keeps hitting its limit on **open** rows, the answer is a kill pass at the weekly review, not a
bigger number. That distinction is the whole discipline.

## Turning a guard off

`brain/tools/brain-guard.sh` is a plain bash script. Delete the numbered block you don't want.

The secret-shape scan in check 4 is the one most worth **extending** rather than removing. Add your
own providers' key prefixes to the regex.

To bypass once, for a genuine emergency: `git commit --no-verify`. Then fix whatever it caught.

## Adding a routine

Two files, and the split matters:

1. **The spec** in `brain/routines/<name>.md`. All the logic lives here: trigger, steps, guardrails,
   what it writes.
2. **The command** in `.claude/commands/<name>.md`. Frontmatter plus about three lines that point at
   the spec.

Keeping the command thin means there's exactly one source of truth. A command that restates the
routine will drift from it, and then you have two versions and no way to know which one ran.

If the routine needs a cadence, add a block to `brain/routines/config.json` with a `last_run`
watermark, and have the session-start read check it. That's the whole scheduling system.

## Adding a slash command

Drop a markdown file in `.claude/commands/`. The filename is the command name.

```markdown
---
description: One line, shown in the command list
argument-hint: (what arguments it takes)
---

# /yourcommand

What you want done.
```

## Changing the reply contract

`brain/tools/reply-brevity.sh`. Edit the heredoc.

Keep it a **soft** constraint with an escape hatch. A hard limit like "three bullets maximum" is
worse than having no rule at all, because it clips exactly the answers that needed room, and then
you stop trusting the output.

To disable entirely: remove the `UserPromptSubmit` block from `.claude/settings.json`. One edit,
reversible.

## The dashboard

`dashboard/index.html` is a single file: vanilla HTML, CSS, and JS, no framework, no build step.
Colors are CSS custom properties at the top; light and dark switch on `data-theme`.

`serve.py` is Python standard library only. Add a route by adding a branch in `do_GET` or `do_POST`.

If you add a write route, keep the three guards the existing ones use: the origin check, the
`Content-Type` requirement, and `save_json` (which writes atomically and keeps a backup). Dropping
any of those turns a local convenience into something any website you visit can drive.

Change the port with `PORT=8123 python3 serve.py`.

## Using it with something other than Claude Code

`AGENTS.md` is the same contract for anything that reads `AGENTS.md` (Codex, Cursor, and others).
**If you edit one, edit both.** A drifted copy is worse than no copy.

Two pieces are Claude Code specific and don't transfer: `.claude/commands/` and the
`UserPromptSubmit` hook. Everything else is plain files, and the brain works fine when read by hand.

## Making your fork public

Read the Security section of the README first. Short version: blank `facts-core.md` and any real
names, then check `git log -p` before pushing, because the guard only catches commits made after you
installed it, and git history is forever.
