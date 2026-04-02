#!/usr/bin/env bash
# Hook: PreToolUse on EnterPlanMode
# Transitions the top-of-stack issue's PDCA label to pdca:plan
# and updates the local issue-stack.md cache.

set -euo pipefail

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
Write your plan using plan mode. It will be automatically posted to the GitHub issue when you exit plan mode.

Your plan MUST include these sections to pass the exit gate:

## Decomplection Review
## Risk Assessment

You do NOT write these yourself. When you call ExitPlanMode, if these sections are missing, you will be instructed to dispatch two independent review agents (in parallel) that cold-read your plan and write these sections. This ensures unbiased review — the agents have no conversation history or attachment to your design.

The agents will:
1. Evaluate decomplection against the skill's Implementation Checklist
2. Run /derisk to validate assumptions at the REPL

Plans missing these sections will be blocked from exiting plan mode.
Plans with MEDIUM/HIGH risk will be escalated to the user.
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
