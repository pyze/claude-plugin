#!/usr/bin/env bash
# Hook: PreToolUse on EnterPlanMode
# Transitions the top-of-stack issue's PDCA label to pdca:plan
# and updates the local issue-stack.md cache.

set -euo pipefail

# Clean up stale review agent temp files from previous plan cycles
rm -f /tmp/plan-decomplection-review.md /tmp/plan-risk-assessment.md

STACK="$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
[ -f "$STACK" ] || exit 0

ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#')
[ -n "$ISSUE" ] || exit 0

# Check current PDCA label
LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' 2>/dev/null)

CURRENT_PDCA=""
for phase in plan do check react; do
  if echo "$LABELS" | grep -q "pdca:$phase"; then
    CURRENT_PDCA="$phase"
    break
  fi
done

# Print reminder regardless of current phase
TITLE=$(gh issue view "$ISSUE" --json title -q '.title' 2>/dev/null || echo "unknown")
cat <<EOF
PDCA PLAN PHASE (#$ISSUE: $TITLE):

=== KEY PRINCIPLES — plan with these in mind ===
- TDD: Every deliverable should specify tests BEFORE implementation. Plan the test, then the code.
- DECOMPLECT: Each component should have one role, one concept (simple = one fold, not interleaved). All dependencies explicit. State is never simple — minimize it.
- DDRY: Shared code must be composable, not just not-repeated. If an extraction takes a mode parameter, split it.
- FAIL-FAST: Fix the source of missing data. No fallback code paths in production.
===

Write your plan using plan mode. It will be automatically posted to the GitHub issue when you exit plan mode.

Your plan MUST include these sections to pass the exit gate:

## Decomplection Review
## Risk Assessment

BEFORE calling ExitPlanMode, dispatch two independent review agents IN PARALLEL:

1. DECOMPLECTION REVIEW AGENT — give it ONLY the plan file + decomplection-first-design skill.
   Writes to /tmp/plan-decomplection-review.md.
2. DERISK AGENT — give it ONLY the plan file + /derisk command + REPL access.
   Writes to /tmp/plan-risk-assessment.md. Each assumption must have a RISK: line. Gate checks each individually.

These must be SEPARATE agents with no conversation history — this ensures unbiased review.

When both complete, append their output to your plan as ## Decomplection Review and ## Risk Assessment, then call ExitPlanMode.

Do NOT call ExitPlanMode without these sections — it will be denied.
Plans with MEDIUM/HIGH risk will be escalated to the user.

REPL exploration is always allowed in every PDCA phase — it never changes production code. Use it freely to validate assumptions and test data shapes.
EOF

# Already in plan — skip label transition
[ "$CURRENT_PDCA" = "plan" ] && exit 0

# Transition to pdca:plan
if [ -n "$CURRENT_PDCA" ]; then
  gh issue edit "$ISSUE" --remove-label "pdca:$CURRENT_PDCA" --add-label "pdca:plan" >/dev/null 2>&1
else
  gh issue edit "$ISSUE" --add-label "pdca:plan" >/dev/null 2>&1
fi

# Update local stack cache
if [ -n "$CURRENT_PDCA" ]; then
  sed -i '' "s/(${CURRENT_PDCA})/(plan)/" "$STACK" 2>/dev/null || true
else
  # If no phase marker, add one
  sed -i '' "s/^- #${ISSUE} —\(.*\)$/- #${ISSUE} —\1 (plan)/" "$STACK" 2>/dev/null || true
fi

echo "PDCA: Transitioned #$ISSUE from ${CURRENT_PDCA:-none} → plan (entering plan mode)"
