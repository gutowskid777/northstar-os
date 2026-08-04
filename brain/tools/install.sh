#!/bin/bash
# install.sh — wires up the one thing a git clone can't do for you.
#
# Git hooks live in .git/hooks/, which is not tracked and not cloned. So brain-guard.sh ships in
# the repo where you can read it, and this links it into place. Run it once after cloning.
#
#   bash brain/tools/install.sh
#
# Idempotent. Safe to re-run.
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "✖ Not inside a git repository."
  echo "  The pre-commit guard is the enforcement layer of this system, so it needs git."
  echo "  Run:  git init && bash brain/tools/install.sh"
  exit 1
}
ROOT=$(pwd)

echo "northstar-os install"
echo "===================="
echo

# --- 1. python3 ------------------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
  echo "  ✓ python3  $(python3 --version 2>&1 | cut -d' ' -f2)"
else
  echo "  ✖ python3 not found."
  echo "    Needed by: the dashboard server (serve.py) and the queue schema check in brain-guard."
  echo "    macOS: xcode-select --install    Debian/Ubuntu: sudo apt install python3"
  exit 1
fi

# --- 2. the pre-commit hook ------------------------------------------------------------------
HOOK_DIR=$(git rev-parse --git-path hooks)
mkdir -p "$HOOK_DIR"
HOOK="$HOOK_DIR/pre-commit"

if [ -e "$HOOK" ] && ! grep -q 'brain-guard.sh' "$HOOK" 2>/dev/null; then
  cp "$HOOK" "$HOOK.pre-northstar.bak"
  echo "  ! An existing pre-commit hook was backed up to $(basename "$HOOK").pre-northstar.bak"
fi

cat > "$HOOK" <<'SHIM'
#!/bin/bash
# Installed by brain/tools/install.sh. The logic lives in the repo so it's reviewable.
exec "$(git rev-parse --show-toplevel)/brain/tools/brain-guard.sh"
SHIM
chmod +x "$HOOK"
chmod +x "$ROOT/brain/tools/brain-guard.sh" "$ROOT/brain/tools/reply-brevity.sh"
echo "  ✓ pre-commit hook installed → brain/tools/brain-guard.sh"

# --- 3. prove the guard actually fires -------------------------------------------------------
# A hook you haven't seen block anything is a hook you don't trust. So trip it on purpose.
echo -n "  · testing the guard... "
TMPQ=$(mktemp)
cp "$ROOT/brain/queue.json" "$TMPQ"

# Unstage helper: `git restore --staged` needs a HEAD, which a freshly-init'd repo doesn't have.
unstage_queue() {
  if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    git restore --staged brain/queue.json >/dev/null 2>&1 || true
  else
    git rm -q --cached brain/queue.json >/dev/null 2>&1 || true
  fi
}

python3 - "$ROOT/brain/queue.json" <<'PY'
import json, sys
p = sys.argv[1]
q = json.load(open(p))
q["_meta"]["count"] = 9999          # deliberately wrong: the guard must catch this
json.dump(q, open(p, "w"), indent=2)
PY
git add brain/queue.json >/dev/null 2>&1 || true
if git commit -q -m "brain-guard self-test (this commit must fail)" >/dev/null 2>&1; then
  echo "FAILED"
  echo "    ✖ The guard did NOT block a commit with a deliberately wrong _meta.count."
  echo "      Undoing the test commit and restoring your queue."
  git reset -q --soft HEAD~1 2>/dev/null || true
  unstage_queue
  cp "$TMPQ" "$ROOT/brain/queue.json"
  rm -f "$TMPQ"
  exit 1
fi
unstage_queue
cp "$TMPQ" "$ROOT/brain/queue.json"
rm -f "$TMPQ"
echo "blocked a bad commit, as it should"

# --- 4. restamp the seed dates to today ------------------------------------------------------
# The example data ships with fixed dates, so a clone six months after release opens showing
# "203d old" on every card and reads as an abandoned demo. This shifts every date in the seed
# forward so the newest becomes today, preserving the relative gaps between them.
#
# Runs ONCE and only on untouched seed data: it keys off _meta.seed in brain/queue.json and
# removes that marker when it's done. Your own rows are never touched.
if python3 -c "import json,sys; sys.exit(0 if json.load(open('brain/queue.json'))['_meta'].get('seed') else 1)" 2>/dev/null; then
  python3 - <<'PY'
import json, re, datetime, pathlib

FILES = ["brain/queue.json", "dashboard/data/projects.json",
         "dashboard/data/life-data.json", "dashboard/data/morning-brief.json"]
# No trailing \b: it would fail on "2026-01-15T07:00:00Z", because the boundary between
# "5" and "T" doesn't exist and morning-brief's generated_at would never be restamped.
DATE = re.compile(r"(?<![\d-])(\d{4})-(\d{2})-(\d{2})")

# Anchor on the QUEUE's newest date, not the newest across every file. Anchoring on the max
# would mean one file carrying a recent date silently disables the whole restamp.
blobs = {}
newest = None
for f in FILES:
    p = pathlib.Path(f)
    if not p.exists():
        continue
    text = p.read_text()
    blobs[f] = text
    if f != "brain/queue.json":
        continue
    for m in DATE.finditer(text):
        try:
            d = datetime.date(*map(int, m.groups()))
        except ValueError:
            continue
        if newest is None or d > newest:
            newest = d

if newest:
    shift = datetime.date.today() - newest
    def bump(m):
        try:
            return (datetime.date(*map(int, m.groups())) + shift).isoformat()
        except ValueError:
            return m.group(0)
    for f, text in blobs.items():
        pathlib.Path(f).write_text(DATE.sub(bump, text))
    print("  ✓ seed dates restamped to today (shifted %d days)" % shift.days)

q = json.loads(pathlib.Path("brain/queue.json").read_text())
q["_meta"].pop("seed", None)
q["_meta"]["count"] = len(q["items"])
pathlib.Path("brain/queue.json").write_text(json.dumps(q, indent=2, ensure_ascii=False) + "\n")
PY
fi

# --- 5. what's next --------------------------------------------------------------------------
cat <<'NEXT'

  Done. Two things left:

    1.  claude        then type  /setup
        It interviews you and writes your goals, facts, working style, and first queue rows.

    2.  python3 serve.py
        The dashboard, at http://127.0.0.1:8000 — localhost only, no dependencies.

  The guard now runs on every commit in this repo. To see the rest of what's enforced:
  docs/how-it-works.md
NEXT
