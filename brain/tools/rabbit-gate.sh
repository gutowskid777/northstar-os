#!/bin/bash
# rabbit-gate.sh — UserPromptSubmit hook. The mechanism behind rules.md §3.
#
# THE POINT: "don't let me rabbit-hole" is the promise this whole system makes, and until this
# file existed it was the one promise backed by nothing but prose. rules.md said to call drift
# out loud "when you're sure" — which every long session reads as permission to let it slide,
# because by turn forty the rule is 30,000 tokens behind the conversation and the model is
# agreeing with you instead of watching you.
#
# So the gate rides next to EVERY message instead of being read once at boot:
#   1. it names your live #1 move, pulled fresh from your own files,
#   2. it requires a one-line verdict BEFORE any work — SHIP / UPKEEP / RABBIT,
#   3. it string-matches the phrases people use while talking themselves into a detour, and
#      fires a tripwire when one shows up.
#
# RABBIT means: say it plainly, file the ask as a queue row, and do nothing else until the user
# types the override word. A blocked turn costs one message. A rabbit hole costs an evening.
#
# The override word is deliberately a word you have to type on purpose. "go ahead" and "yes"
# are things you say by reflex; "override" is a decision.
#
# Turn it off: remove this command from .claude/settings.json. Tune it: edit TRIPWIRES below.
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# --- 1. the live #1 -------------------------------------------------------------------------
# your-move.md if the Your Move routine has written one, else the first ranked line in goals.md.
MOVE=""
[ -f "$ROOT/brain/your-move.md" ] && MOVE=$(grep -m1 -E '^1\. ' "$ROOT/brain/your-move.md" 2>/dev/null | cut -c1-220)
if [ -z "$MOVE" ] && [ -f "$ROOT/brain/goals.md" ]; then
  MOVE=$(awk '/^## Top 3/{f=1;next} f&&/^1\. /{print;exit}' "$ROOT/brain/goals.md" 2>/dev/null | cut -c1-220)
fi

echo "[rabbit-hole gate — every turn]"
case "$MOVE" in
  ""|*"Not set yet"*)
    echo "Live #1 move: NOT SET. brain/goals.md is still a placeholder, so nothing here can be"
    echo "ranked and every verdict below is a guess. Say so in one line and offer /setup." ;;
  *) echo "Live #1 move: $MOVE" ;;
esac

# --- 2. the verdict contract ----------------------------------------------------------------
cat <<'EOT'
Before any work, the reply opens with ONE line: "Gate: SHIP" (moves the #1 goal, or a dated
real-world obligation such as an exam, a filing or a deploy that is due), "Gate: UPKEEP" (serves a
lower-ranked goal, bounded, and must not delay the #1), or "Gate: RABBIT" (neither). RABBIT means:
say it plainly, file the ask as a queue row so it is never lost, and do NOTHING else until the user
types the override word "override". No softening. "It's small" is not a defense, and the user saying
they are not rabbit-holing does not change the verdict. When the move this session was opened for
has shipped, retire the session instead of finding a next thing.
EOT

# --- 3. the tripwire ------------------------------------------------------------------------
# These are the phrases people type while deciding to do the thing anyway. The pattern is a
# pre-emptive defense against an objection nobody made yet. Add your own tells as you notice them.
TRIPWIRES="just this one|real quick|quick thing|quick one|not a rabbit hole|not tryna|not trying to rabbit|before i (leave|go)|one more thing|while i'm here|while im here|small thing|might as well|then i'll (leave|stop)|and leave|just gonna|shouldn't take long|super quick|last thing"

PROMPT=$(cat 2>/dev/null | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("prompt",""))
except Exception: print("")' 2>/dev/null)
HIT=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]' | grep -oiE "$TRIPWIRES" | head -1)

if [ -n "$HIT" ]; then
  cat <<EOT

🚧 TRIPWIRE: this message contains "$HIT". That phrasing IS the rabbit-hole pattern — it is a
defense raised before anyone objected. Verdict first, work second, and RABBIT stays RABBIT until
the override word.
EOT
fi
exit 0
