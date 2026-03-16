#!/bin/bash
# Blocks creation of local plan/todo files — forces use of GitHub Issues.
# Exit code 2 = block the tool call and send the message back to Claude.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

# Block common local planning file patterns
case "$BASENAME" in
  plan.md|plans.md|todo.md|todos.md|tasks.md|roadmap.md|backlog.md|spec.md|design.md)
    echo "BLOCKED: Do not create local plan files. Use GitHub Issues as the planning surface. Create or update a GitHub issue instead. NOTE: Updating GitHub issues in plan mode IS allowed and encouraged — use gh or GitHub MCP tools." >&2
    exit 2
    ;;
esac

# Also catch files in a plans/ or planning/ directory
case "$FILE_PATH" in
  */plans/*|*/planning/*)
    echo "BLOCKED: Do not create files in plans/ or planning/ directories. Use GitHub Issues as the planning surface. NOTE: Updating GitHub issues in plan mode IS allowed and encouraged — use gh or GitHub MCP tools." >&2
    exit 2
    ;;
esac

exit 0
