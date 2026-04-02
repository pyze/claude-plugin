#!/bin/bash
set -euo pipefail

# ExitPlanMode hook: require active GitHub issue + post plan in background.
# - No active issue → deny
# - No plan file → allow through silently
# - Plan exists → post to issue (backgrounded), allow through

STACK="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/issue-stack.md"

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
plan_file=$(ls -t "${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/plans/"*.md 2>/dev/null | head -1 || true)

# No plan file → allow through
if [ -z "$plan_file" ]; then
  exit 0
fi

# Build comment body: plan + PDCA reminder
PDCA_REMINDER='
---
## PDCA Reminder
This issue follows the PDCA cycle. When all tasks above are complete:
1. Update the issue label from `pdca:do` → `pdca:check`
2. Update `.claude/issue-stack.md` phase from `do` → `check`
3. Enter plan mode
4. Review all changes against this plan and post a gap analysis as a comment
5. Evaluate all touched files for purity violations — present for user approval
6. Run fallback code scan (missing data fallbacks + refactoring fallbacks)
7. Reflect on lessons learned during Do — save durable insights to auto-memory
8. Present the gap analysis to the user and transition to `react`
Do not close this issue or declare done until the full cycle completes.'

COMMENT_BODY="$(cat "$plan_file")
${PDCA_REMINDER}"

# Post plan + PDCA reminder to issue as comment (backgrounded — fire-and-forget)
gh issue comment "$ISSUE" --body "$COMMENT_BODY" >/dev/null 2>&1 &

exit 0
