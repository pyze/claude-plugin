#!/bin/bash
# Pyze plugin status line — shows issue stack, PDCA phase, model, and context usage.
#
# Install by adding to your settings.json (project or user level):
#   "statusLine": {
#     "type": "command",
#     "command": "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
#   }
#
# Or copy this script and customize.

set -euo pipefail

input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Issue stack — read top issue from local file
ISSUE_INFO=""
STACK_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"
if [ -f "$STACK_FILE" ]; then
  TOP=$(grep -E '^- #' "$STACK_FILE" | head -1 || true)
  if [ -n "$TOP" ]; then
    # Extract: "- #52 — Fix auth (do)" → "#52 (do)"
    ISSUE_NUM=$(echo "$TOP" | grep -oE '#[0-9]+' | head -1)
    PHASE=$(echo "$TOP" | grep -oE '\([a-z]+\)$' || echo "")
    if [ -n "$ISSUE_NUM" ]; then
      ISSUE_INFO=" ${ISSUE_NUM} ${PHASE}"
    fi
  fi
fi

# Cost (if available)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
if [ "$COST" != "0" ] && [ -n "$COST" ]; then
  COST_FMT=$(printf '$%.2f' "$COST")
else
  COST_FMT=""
fi

# Build output
OUTPUT="[${MODEL}]"

if [ -n "$ISSUE_INFO" ]; then
  OUTPUT="${OUTPUT}${ISSUE_INFO} |"
fi

OUTPUT="${OUTPUT} ${PCT}% ctx"

if [ -n "$COST_FMT" ]; then
  OUTPUT="${OUTPUT} | ${COST_FMT}"
fi

echo "$OUTPUT"
