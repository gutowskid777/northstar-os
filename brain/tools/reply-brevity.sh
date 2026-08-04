#!/bin/bash
# reply-brevity.sh — a UserPromptSubmit hook.
#
# This is the highest-leverage file in the repo, and it is nine lines of cat.
#
# The problem it solves: a rule written in a markdown file is read ONCE, at session start, and
# then buried under everything that happens after. By turn forty it has no weight at all. You can
# write the same rule in seven different files and it still fades, because the failure isn't that
# the rule was missing. The failure is distance.
#
# A UserPromptSubmit hook fires on every single message, so the contract arrives adjacent to the
# newest turn instead of a hundred messages upstream. Same words, completely different outcome.
#
# That's the general lesson, and it's why brain/rules.md §11 exists: when a rule keeps getting
# violated, don't rewrite the rule. Move it somewhere it can't fade.
#
# Edit the text below to change your reply contract. Keep it a SOFT constraint with an escape
# hatch — a hard "3 bullets max" is worse than no rule, because it clips the answers that
# genuinely needed room.
#
# Disable: remove the UserPromptSubmit block from .claude/settings.json. One edit, reversible.
cat <<'EOF'
[reply format — every turn] Lead with the answer. Short by default; match length to what the
answer genuinely needs, and never pad. No process narration, no restating what you just did.
Findings and detail go in the commit message or a file and the reply POINTS at them — don't dump
them in chat. Expand fully only when this message asks for it (expand / detail / full / walk me through).
EOF
