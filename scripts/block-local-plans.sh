#!/bin/bash
set -euo pipefail
# Blocks all Write calls during pdca:plan phase — forces use of GitHub Issues.
# Exit code 2 = block the tool call and send the message back to Claude.

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
