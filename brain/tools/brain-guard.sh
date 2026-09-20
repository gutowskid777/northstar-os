#!/bin/bash
# brain-guard.sh — pre-commit enforcement for northstar-os.
#
# THE POINT: these checks fire on every commit with zero goodwill and zero memory required.
# Every rule in brain/rules.md that actually survives a long session is backed by something
# mechanical, and this is most of that something. Prose relapses. Hooks hold.
#
# Installed by brain/tools/install.sh, which writes a 3-line shim at .git/hooks/pre-commit that
# execs this file. The logic lives here, versioned, so it's reviewable and diffable.
# Emergency bypass: git commit --no-verify   (then fix whatever it caught)
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1

fail() { echo "" >&2; echo "✖ brain-guard BLOCKED this commit: $1" >&2; echo "" >&2; exit 1; }

STAGED=$(git diff --cached --name-only --diff-filter=ACM)

# ---------------------------------------------------------------------------------------------
# 1. credentials.md is local-only, always.
#    It's in .gitignore, but a `git add -f` or a moved file gets past that. This doesn't.
# ---------------------------------------------------------------------------------------------
if echo "$STAGED" | grep -qx 'brain/credentials.md'; then
  fail "brain/credentials.md is staged. It is local-only — unstage it (git restore --staged brain/credentials.md)."
fi

# ---------------------------------------------------------------------------------------------
# 2. brain-state.md hard caps — the rotation contract (150 lines / 12KB).
#    This file loads at the start of EVERY session. Unbounded, it becomes the most expensive
#    thing you read before doing any work. The cap is what keeps the boot read cheap at month 12.
# ---------------------------------------------------------------------------------------------
if echo "$STAGED" | grep -qx 'brain/brain-state.md'; then
  lines=$(git show :brain/brain-state.md | wc -l | tr -d ' ')
  bytes=$(git show :brain/brain-state.md | wc -c | tr -d ' ')
  if [ "$lines" -gt 150 ]; then
    fail "brain-state.md is $lines lines (cap: 150). Don't append — move superseded content to brain/history/decisions-YYYY-MM.md."
  fi
  if [ "$bytes" -gt 12000 ]; then
    fail "brain-state.md is $bytes bytes (cap: 12000). Don't append — move superseded content to brain/history/decisions-YYYY-MM.md."
  fi
fi

# ---------------------------------------------------------------------------------------------
# 3. queue.json must stay a valid {_meta, items} doc: every row has id/type/status, ids are
#    unique, and _meta.count matches reality. The dashboard writes this file and has no idea
#    the contract exists, so something has to check it.
# ---------------------------------------------------------------------------------------------
if echo "$STAGED" | grep -qx 'brain/queue.json'; then
  tmp=$(mktemp)
  git show :brain/queue.json > "$tmp"
  if ! python3 - "$tmp" <<'PY'
import json, sys
q = json.load(open(sys.argv[1]))
assert isinstance(q, dict), "queue.json must be an object, not an array"
assert q.get("_meta"), "queue.json lost its _meta"
assert isinstance(q.get("items"), list), "queue.json needs an items array"
ids = []
for r in q["items"]:
    for k in ("id", "type", "status"):
        assert r.get(k), "row missing '%s': %r" % (k, r.get("id", r))
    ids.append(r["id"])
dupes = sorted({i for i in ids if ids.count(i) > 1})
assert not dupes, "duplicate ids: %s" % dupes
assert q["_meta"].get("count") == len(q["items"]), (
    "_meta.count is %r but there are %d rows — fix the counter" % (q["_meta"].get("count"), len(q["items"])))
PY
  then
    rm -f "$tmp"
    fail "brain/queue.json failed its schema check (see error above)."
  fi
  rm -f "$tmp"

  # 3b. Rotation contract. The queue grows forever if nothing prunes it, and it's a file that
  #     costs real tokens to read whole. Rotate, never delete:
  #     brain/history/queue-closed-YYYY-MM.json.
  qrows=$(git show :brain/queue.json | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["items"]))')
  qbytes=$(git show :brain/queue.json | wc -c | tr -d ' ')
  if [ "$qrows" -gt 250 ]; then
    fail "queue.json is $qrows rows (cap: 250). Rotate closed rows older than this month to brain/history/queue-closed-YYYY-MM.json."
  fi
  if [ "$qbytes" -gt 300000 ]; then
    fail "queue.json is $qbytes bytes (cap: 300000). Rotate closed rows, then kill parked ideas at the weekly review. If OPEN rows alone exceed this, the queue needs pruning, not compressing."
  fi

  # 3c. Mass-erase guard. Rows are never DELETED in normal work: a "kill" keeps the row with
  #     status=killed. Only ROTATION removes ids, and a rotation stages a
  #     brain/history/queue-closed-*.json in the same commit. So: a staged queue.json missing
  #     >10 ids that HEAD has, with no rotation file staged, is a stale session overwriting the
  #     file from an old snapshot. That failure is SILENT — nothing errors, the rows are just
  #     gone — which is exactly why it needs a mechanical check.
  #     Fails OPEN on any error (python/git hiccup allows the commit) so it can never brick a
  #     legitimate commit.
  if git cat-file -e HEAD:brain/queue.json 2>/dev/null; then
    rotated=0
    echo "$STAGED" | grep -q 'brain/history/queue-closed-' && rotated=1
    dropped=$(python3 - "$rotated" <<'PY' 2>/dev/null || echo 0
import json, subprocess, sys
def ids(ref):
    out = subprocess.run(["git","show",ref], capture_output=True, text=True)
    return {r["id"] for r in json.loads(out.stdout)["items"]}
try:
    if sys.argv[1] == "1":
        print(0)
    else:
        print(len(ids("HEAD:brain/queue.json") - ids(":brain/queue.json")))
except Exception:
    print(0)
PY
)
    if [ "${dropped:-0}" -gt 10 ]; then
      fail "staged queue.json drops $dropped rows that HEAD has, and no rotation file is staged — this looks like a stale-session overwrite. Re-read the current queue.json and merge your rows in by id. If this genuinely IS a rotation, stage the brain/history/queue-closed-*.json in the same commit."
    fi
  fi
fi

# ---------------------------------------------------------------------------------------------
# 4. API-key-shaped strings in staged additions. Fails closed.
#    Short placeholders (sk-ant-xxx, YOUR_KEY_HERE) stay under the length thresholds on purpose.
#    Add your own providers' key prefixes here.
# ---------------------------------------------------------------------------------------------
if git diff --cached -U0 | grep -E '^\+' | grep -qE \
   'sk-ant-[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9]{40,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|sbp_[A-Za-z0-9]{20,}|re_[A-Za-z0-9]{24,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}'; then
  fail "staged diff contains an API-key-shaped string. Secrets belong in .env or brain/credentials.md — both untracked."
fi

# ---------------------------------------------------------------------------------------------
# 5. Nothing over 5MB. Big assets belong outside git; a repo that has swallowed one is painful
#    to fix later.
# ---------------------------------------------------------------------------------------------
while IFS= read -r f; do
  [ -z "$f" ] && continue
  size=$(git cat-file -s ":$f" 2>/dev/null || echo 0)
  if [ "$size" -gt 5242880 ]; then
    fail "$f is staged at >5MB. Keep big binaries out of the repo."
  fi
done <<< "$STAGED"

# ---------------------------------------------------------------------------------------------
# 6. THE TREE. One structure, every level, enforced instead of described.
#
#    A folder layout is a rule like any other: written down once, obeyed for a week, and then
#    quietly violated by the fourth parallel session that needed somewhere to put a file. The
#    cost shows up months later as four places to look for one thing. So the shape lives here.
#
#    The root has four kinds and nothing else:
#      brain/      the OS: state, rules, goals, queue, routines, tools, history
#      projects/   one folder per project, each with a MANDATORY context.md
#      dashboard/  the local dashboard's page and seed data (docs/ and example/ ship with the repo)
#      _trash/     gitignored. Retired things move here; nothing is ever rm'd.
#
#    Adding a new kind of thing is allowed — it takes editing this list and brain/doc-structure.md
#    in the same commit, which is exactly the amount of friction that keeps it deliberate.
# ---------------------------------------------------------------------------------------------
ROOT_ALLOW='^(brain|projects|dashboard|docs|example)/|^\.claude/|^\.github/|^(\.gitignore|CLAUDE\.md|AGENTS\.md|README\.md|LICENSE|serve\.py)$'
BRAIN_ALLOW='^brain/(README|brain-state|goals|rules|rules\.local|facts-core|doc-structure)\.md$|^brain/queue\.json$|^brain/your-move\.md$|^brain/(docs|history|routines|tools)/'

while IFS= read -r f; do
  [ -z "$f" ] && continue

  if ! echo "$f" | grep -qE "$ROOT_ALLOW"; then
    fail "'$f' is outside the tree. A project goes in projects/<name>/, OS files in brain/, retired things in _trash/ (gitignored). See brain/doc-structure.md § The tree."
  fi

  # Nothing loose in projects/ — every file belongs to exactly one project.
  case "$f" in
    projects/*/*) ;;
    projects/*) fail "'$f' sits directly in projects/. Every file belongs inside projects/<name>/." ;;
  esac

  # A project without a map is a project nobody can pick up later, including you.
  case "$f" in
    projects/*)
      proj=$(echo "$f" | cut -d/ -f2)
      if ! git cat-file -e ":projects/$proj/context.md" 2>/dev/null; then
        fail "projects/$proj/ has no context.md. Every project starts with one — what it is, plus a Docs Index. Template: brain/doc-structure.md. Add it in this commit."
      fi ;;
  esac

  # brain/ root holds only what loads at session start. Everything else has a named home:
  # docs/ standing docs · history/ dated and dead · routines/ recurring jobs · tools/ scripts.
  case "$f" in
    brain/*)
      echo "$f" | grep -qE "$BRAIN_ALLOW" || fail "'$f' breaks the brain/ tree. Root = the core files only (brain-state, goals, rules, rules.local, facts-core, queue.json, doc-structure, your-move, README). Standing docs -> brain/docs/, dated or superseded -> brain/history/, recurring jobs -> brain/routines/, scripts -> brain/tools/." ;;
  esac
done <<< "$STAGED"

exit 0
