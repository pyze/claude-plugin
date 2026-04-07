#!/bin/bash
set -euo pipefail

# ExitPlanMode hook: marker-based gate with derisk result verification.
# Checks plan file for ## Decomplection Review and ## Risk Assessment.
# If missing → deny with instructions to dispatch review agents.
# If present → verify derisk result file for risk level.

# Get active issue number for messages
STACK="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/issue-stack.md"
ISSUE=""
if [ -f "$STACK" ]; then
  ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)
fi

# Find most recent plan file — check both user-level and project-level directories
plan_file=$(ls -t "$HOME/.claude/plans/"*.md "${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/plans/"*.md 2>/dev/null | head -1 || true)

# No plan file → allow through
if [ -z "$plan_file" ]; then
  exit 0
fi

# Check for required markers
has_decomplection=false
has_risk=false

grep -q '^## Decomplection Review' "$plan_file" && has_decomplection=true
grep -q '^## Risk Assessment' "$plan_file" && has_risk=true

# Build list of missing markers
missing=""
if [ "$has_decomplection" = false ]; then
  missing="${missing}\n[ ] ## Decomplection Review"
fi
if [ "$has_risk" = false ]; then
  missing="${missing}\n[ ] ## Risk Assessment"
fi

# If any markers missing → deny with agent dispatch instructions
if [ -n "$missing" ]; then
  # Build JSON using python3 to handle all escaping correctly
  python3 -c "
import json, sys
missing = sys.argv[1]
reason = '''PLAN REVIEW REQUIRED — missing sections:''' + missing + '''

Your plan must include these sections to exit plan mode. Dispatch two independent review agents IN PARALLEL to write them.

=== REQUIRED SECTIONS ===

## Decomplection Review
Format: for each plan deliverable, evaluate against these criteria:
- No hidden dependencies (all inputs explicit as args)
- No mixed concerns (one responsibility per component)
- Easy to test (simple inputs, no complex setup)
- Reusable (works in REPL, tests, multiple contexts)
- Composable (output feeds into other functions)
- Pure or boundary-marked (! suffix for side effects)
List each deliverable with PASS/FAIL per criterion. Note revision suggestions for failures.

## Risk Assessment
Format: list each assumption with:
- ASSUMPTION: [what the plan depends on]
- STATUS: Validated/Unvalidated
- RISK: NONE/LOW/MEDIUM/HIGH
- EVIDENCE: [how it was validated, or why it couldn't be]
The gate checks each RISK: line individually. Any MEDIUM/HIGH blocks until resolved or ACCEPTED by user.

=== AGENT DISPATCH ===

1. DECOMPLECTION REVIEW AGENT
   Give it ONLY: the plan file + decomplection-first-design skill
   Output: write to /tmp/plan-decomplection-review.md

2. DERISK AGENT
   Give it ONLY: the plan file + /derisk command + REPL access
   Output: write to /tmp/plan-risk-assessment.md
   Each assumption must have a RISK: line. Gate checks each individually.

IMPORTANT: agents write to SEPARATE temp files to avoid clobbering.
They must be SEPARATE agents with no conversation history.

When both agents complete:
1. Append /tmp/plan-decomplection-review.md to the plan as ## Decomplection Review
2. Append /tmp/plan-risk-assessment.md to the plan as ## Risk Assessment
3. Call ExitPlanMode again.'''
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': reason}}))
" "$missing"
  exit 0
fi

# Both markers present — scan every RISK: line in the Risk Assessment section
# Extract all RISK: values between ## Risk Assessment and the next ## heading
risk_lines=$(awk '/^## Risk Assessment/{found=1; next} found && /^## /{exit} found && /RISK:/{print}' "$plan_file")

# No RISK: lines found
if [ -z "$risk_lines" ]; then
  cat <<'DENY'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "NO RISK ENTRIES FOUND\n\nThe ## Risk Assessment section exists but contains no RISK: lines.\n\nEach assumption must have a RISK: NONE/LOW/MEDIUM/HIGH/ACCEPTED line.\nAdd risk entries, then call ExitPlanMode again."
  }
}
DENY
  exit 0
fi

# Check for MEDIUM or HIGH risks that haven't been ACCEPTED
blocking_risks=$(echo "$risk_lines" | grep -iE 'RISK:\s*(MEDIUM|HIGH)' || true)

if [ -n "$blocking_risks" ]; then
  # Format the blocking risks for display
  python3 -c "
import json, sys
lines = sys.argv[1].strip()
reason = 'UNRESOLVED RISKS\n\nThe following assumptions have MEDIUM or HIGH risk:\n\n' + lines + '\n\nDo NOT loop /derisk again.\n\nPresent these risks to the user and ask how they want to proceed:\n- Accept the risks and continue\n- Revise the plan to avoid the risky areas\n- Validate the assumptions to reduce risk\n\nIf the user accepts a risk, change its RISK: line to RISK: ACCEPTED\n\nThen call ExitPlanMode again.'
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': reason}}))
" "$blocking_risks"
  exit 0
fi

# All risks are NONE, LOW, or ACCEPTED — approve
if [ -n "$ISSUE" ]; then
  echo "PLAN APPROVED — transitioning to Do phase. Before dispatching subagents, read the plan from GitHub issue #$ISSUE (gh issue view $ISSUE --comments). The issue comment contains the full plan + PDCA reminder. Include the plan content and Core Assumptions in each subagent's task description."
fi
exit 0
