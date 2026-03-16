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
PDCA REMINDER: You are now in the PLAN phase of PDCA for issue #$ISSUE ($TITLE).
Plan phase means: analyze, design, and write the plan as comments on the GitHub issue. Do NOT implement code changes. Do NOT execute the plan. Do NOT write plan files to the local filesystem. Planning only — research, read code, ask questions, document the plan on the GitHub issue.
Allowed in plan mode: REPL evaluation (clojure_eval MCP tool) to validate assumptions and test data shapes. GitHub issue CRUD (gh issue create/edit/view, MCP issue tools) to read and update plans. Plans live on GitHub Issues, not in local files.
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
