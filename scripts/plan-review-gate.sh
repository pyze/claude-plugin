#!/bin/bash
set -euo pipefail

# ExitPlanMode hook: marker-based gate with derisk result verification.
# Checks plan file for ## Decomplection Review and ## Risk Assessment.
# If missing → deny with instructions to dispatch review agents.
# If present → verify derisk result file for risk level.

# Find most recent plan file
plan_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
plan_file=$(ls -t "$plan_dir"/*.md 2>/dev/null | head -1 || true)

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
  reason="PLAN REVIEW REQUIRED — missing sections:${missing}\n\nDispatch these agents IN PARALLEL:\n\n1. DECOMPLECTION REVIEW AGENT\n   Give it ONLY: the plan file + decomplection-first-design skill\n   Task: evaluate each deliverable against the Implementation Checklist\n   (no hidden deps, no mixed concerns, testable, reusable, composable, pure)\n   Output: write to /tmp/plan-decomplection-review.md\n\n2. DERISK AGENT\n   Give it ONLY: the plan file + /derisk command + REPL access\n   Task: identify unvalidated assumptions, validate critical ones at REPL\n   Output: write to /tmp/plan-risk-assessment.md\n   with risk level (NONE/LOW/MEDIUM/HIGH) + write derisk result file\n\nIMPORTANT: agents write to SEPARATE temp files to avoid clobbering.\nThey must be SEPARATE agents with no conversation history.\n\nWhen both agents complete:\n1. Append /tmp/plan-decomplection-review.md to the plan as ## Decomplection Review\n2. Append /tmp/plan-risk-assessment.md to the plan as ## Risk Assessment\n3. Call ExitPlanMode again."
  cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$reason"
  }
}
DENY
  exit 0
fi

# Both markers present — verify derisk result file
result_dir="/tmp/claude-derisk-result"
mkdir -p "$result_dir"
plan_hash=$(echo "$plan_file" | shasum -a 256 | cut -d' ' -f1)
result_file="$result_dir/$plan_hash"

if [ ! -f "$result_file" ]; then
  cat <<'DENY'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DERISK RESULT MISSING\n\nThe plan has both review sections, but no derisk result file was written.\nRun /derisk to generate the result file, then call ExitPlanMode again."
  }
}
DENY
  exit 0
fi

risk_level=$(cat "$result_file" | tr '[:lower:]' '[:upper:]')

case "$risk_level" in
  NONE|LOW|ACCEPTED)
    rm -f "$result_file"
    exit 0
    ;;
  *)
    rm -f "$result_file"
    reason="RISKS REMAIN (${risk_level})\n\nDerisking found risks that could not be reduced to LOW. Do NOT loop /derisk again.\n\nPresent the remaining risks to the user and ask how they want to proceed:\n- Accept the risks and continue\n- Revise the plan to avoid the risky areas\n- Abandon this approach\n\nIf the user accepts the remaining risks, write ACCEPTED to the result file before calling ExitPlanMode again:\n\nPLAN_FILE=\$(ls -t \\\"\${CLAUDE_PROJECT_DIR:-.}/.claude/plans/\\\"*.md 2>/dev/null | head -1)\nPLAN_HASH=\$(echo \\\"\$PLAN_FILE\\\" | shasum -a 256 | cut -d' ' -f1)\necho ACCEPTED > \\\"/tmp/claude-derisk-result/\$PLAN_HASH\\\""
    cat <<DENY
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$reason"
  }
}
DENY
    exit 0
    ;;
esac
