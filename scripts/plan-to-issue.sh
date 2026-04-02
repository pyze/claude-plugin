#!/bin/bash
set -euo pipefail

# ExitPlanMode hook: require active GitHub issue + post plan in background.
# - No active issue → deny
# - No plan file → allow through silently
# - Plan exists → post to issue (backgrounded), allow through

STACK="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"

if [ ! -f "$STACK" ]; then
  cat <<'DENY'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "NO ACTIVE ISSUE\n\nCreate a GitHub issue before exiting plan mode. The plan will be automatically posted to the issue.\n\ngh issue create --title \"...\" --body \"...\"\n\nThen add it to .claude/issue-stack.md and call ExitPlanMode again."
  }
}
DENY
  exit 0
fi

ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)

if [ -z "$ISSUE" ]; then
  cat <<'DENY'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "NO ACTIVE ISSUE\n\nThe issue stack is empty. Create a GitHub issue before exiting plan mode.\n\ngh issue create --title \"...\" --body \"...\"\n\nThen add it to .claude/issue-stack.md and call ExitPlanMode again."
  }
}
DENY
  exit 0
fi

# Find most recent plan file
plan_file=$(ls -t "${CLAUDE_PROJECT_DIR:-.}/.claude/plans/"*.md 2>/dev/null | head -1 || true)

# No plan file → allow through
if [ -z "$plan_file" ]; then
  exit 0
fi

# Post plan to issue as comment (backgrounded — fire-and-forget)
gh issue comment "$ISSUE" --body "$(cat "$plan_file")" >/dev/null 2>&1 &

exit 0
