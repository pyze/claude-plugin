#!/bin/bash
# Pyze plugin status line — shows current issue, PDCA phase, branch, model, and context usage.
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

# Git branch
BRANCH=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)

# Issue stack — read top issue from local file
ISSUE_INFO=""
STACK_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"
if [ -f "$STACK_FILE" ]; then
  TOP=$(grep -E '^- #' "$STACK_FILE" | head -1 || true)
  if [ -n "$TOP" ]; then
    ISSUE_NUM=$(echo "$TOP" | grep -oE '#[0-9]+' | head -1 || true)
    DESC=$(echo "$TOP" | sed 's/^- #[0-9]* — //' | sed 's/ ([a-z]*)$//' || true)
    PHASE=$(echo "$TOP" | grep -oE '\([a-z]+\)$' || true)
    if [ -n "$ISSUE_NUM" ]; then
      ISSUE_INFO="${ISSUE_NUM}"
      if [ -n "$DESC" ]; then
        ISSUE_INFO="${ISSUE_INFO} ${DESC}"
      fi
      if [ -n "$PHASE" ]; then
        ISSUE_INFO="${ISSUE_INFO} ${PHASE}"
      fi
    fi
  fi
fi

# Build output
OUTPUT="[${MODEL}] ${PCT}% ctx"

if [ -n "$BRANCH" ]; then
  OUTPUT="${OUTPUT} | ${BRANCH}"
fi

if [ -n "$ISSUE_INFO" ]; then
  OUTPUT="${OUTPUT} | ${ISSUE_INFO}"
fi

echo "$OUTPUT"
