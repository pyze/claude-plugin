#!/bin/bash
set -euo pipefail
# Blocks Write calls during pdca:plan phase — except plan files in .claude/plans/.
# Exit code 2 = block the tool call and send the message back to Claude.

# Exempt plan files — Claude's plan mode writes here
FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)
if [ -n "$FILE_PATH" ]; then
  case "$FILE_PATH" in
    */.claude/plans/*) exit 0 ;;
  esac
fi

STACK="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"

# No issue stack — allow through
if [ ! -f "$STACK" ]; then
  exit 0
fi

ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)

# No active issue — allow through
if [ -z "$ISSUE" ]; then
  exit 0
fi

LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' 2>/dev/null || true)

if echo "$LABELS" | grep -q 'pdca:plan'; then
  echo "BLOCKED: You are in the Plan phase (#$ISSUE). Do not write files during planning. Use GitHub Issues as the planning surface — create or update issue comments with gh or GitHub MCP tools." >&2
  exit 2
fi

exit 0
