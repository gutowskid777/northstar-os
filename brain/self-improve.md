# Self-improvement — the loop
# STATUS: ACTIVE
# Pulled on demand. The one-line trigger lives in rules.md §11.

The brain gets better by turning recurring friction into durable fixes. Concisely, not with
frameworks.

## When to run

- The SAME workflow problem hits twice (confusion, an edit to the wrong doc, lost context, a manual
  step you keep redoing), OR
- The user says "fix this in the brain."

## The loop (keep it small)

1. **Name the root cause in one line.** What actually went wrong, not the symptom. "It forgot the
   rule" is a symptom. "The rule was read once at boot and buried by turn forty" is a root cause,
   and it implies a completely different fix.
2. **Write the smallest durable fix, into exactly ONE home.** Ranked by how well it holds:
   - a **hook or script** → `brain/tools/` — fires whether or not anyone remembers it
   - a **schema check or cap** → `brain-guard.sh` — fails loudly at commit time
   - a **routine spec** → `brain/routines/` — for something that recurs on a cadence
   - a **rule** → `brain/rules.md` (generic) or `rules.local.md` (yours)
   Prefer the top of that list. A rule is the weakest fix available and should be the last resort,
   not the first instinct.
3. **Register it** so future sessions actually apply it: a pointer in `rules.md`, or an entry in
   the routine config.
4. **Stop.** One fix, not a system. If it needs more than a paragraph, that's a rabbit hole wearing
   a productivity costume.

## Guardrail

Don't self-improve on one-offs or on speculation. Only on friction that genuinely recurred, or that
the user flagged. Bias to the smallest change that prevents the repeat.

The test for whether a fix will hold: **if everyone involved forgot this rule tomorrow, would it
still work?** If yes, it's a mechanism. If no, you wrote a reminder and called it a fix.
