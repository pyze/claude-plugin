#!/bin/bash
set -euo pipefail

# Derisk gate — runs on ExitPlanMode.
# Checks /tmp/claude-derisk-result/<plan-hash> for risk level written by /derisk.
# - No result file: deny, tell Claude to run /derisk
# - LOW/NONE: allow through
# - MEDIUM/HIGH: deny, tell Claude to ask user how to proceed

# Find the most recent plan file
plan_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
plan_file=$(ls -t "$plan_dir"/*.md 2>/dev/null | head -1 || true)

if [ -z "$plan_file" ]; then
  # No plan file — allow through
  exit 0
fi

# Result file keyed by plan hash
result_dir="/tmp/claude-derisk-result"
mkdir -p "$result_dir"
plan_hash=$(echo "$plan_file" | shasum -a 256 | cut -d' ' -f1)
result_file="$result_dir/$plan_hash"

if [ ! -f "$result_file" ]; then
  # No derisk result — deny and instruct to run /derisk
  cat <<'DENY'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DERISK REQUIRED\n\nBefore finalizing this plan, run /derisk to identify and validate unvalidated assumptions.\n\n1. Identify unvalidated assumptions in the plan\n2. Validate critical assumptions at the REPL\n3. If a risk cannot be reduced, document why\n\nWhen done, call ExitPlanMode again."
  }
}
DENY
  exit 0
fi

# Read the risk level
risk_level=$(cat "$result_file" | tr '[:lower:]' '[:upper:]')

case "$risk_level" in
  NONE|LOW|ACCEPTED)
    # Risks acceptable or user-accepted — allow through and clean up
    rm -f "$result_file"
    exit 0
    ;;
  *)
    # MEDIUM/HIGH — deny and escalate to user
    rm -f "$result_file"
    reason="RISKS REMAIN (${risk_level})\n\nDerisking found risks that could not be reduced to LOW. Do NOT loop /derisk again.\n\nInstead, present the remaining risks to the user and ask how they want to proceed:\n- Accept the risks and continue\n- Revise the plan to avoid the risky areas\n- Abandon this approach\n\nIf the user accepts the remaining risks, write ACCEPTED to the result file before calling ExitPlanMode again:\n\nPLAN_FILE=\$(ls -t \\\"\${CLAUDE_PROJECT_DIR:-.}/.claude/plans/\\\"*.md 2>/dev/null | head -1)\nPLAN_HASH=\$(echo \\\"\$PLAN_FILE\\\" | shasum -a 256 | cut -d' ' -f1)\necho ACCEPTED > \\\"/tmp/claude-derisk-result/\$PLAN_HASH\\\""
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
