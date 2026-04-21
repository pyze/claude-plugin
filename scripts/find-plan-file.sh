#!/bin/bash
# Shared helper: find the active plan file.
# Called by plan-to-issue.sh and plan-review-gate.sh.
#
# Strategy:
# 1. Read hook stdin for tool_input (ExitPlanMode may provide planPath)
# 2. Fall back to most recently modified plan file within 5 minutes
#
# Outputs the plan file path to stdout. Exits silently if none found.

set -euo pipefail

# Read stdin (hook input JSON) — but only if stdin is available
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT=$(cat)
fi

# Try to extract planPath from hook input
plan_file=""
if [ -n "$HOOK_INPUT" ]; then
  plan_file=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(ti.get('planPath', ti.get('plan_file_path', '')))
except:
    print('')
" 2>/dev/null || true)
fi

# Validate the extracted path
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
  echo "$plan_file"
  exit 0
fi

# Fallback: most recently modified plan file within 5 minutes
NOW=$(date +%s)
FIVE_MIN_AGO=$((NOW - 300))

for f in $(ls -t "$HOME/.claude/plans/"*.md "${CLAUDE_PROJECT_DIR:-.}/.claude/plans/"*.md 2>/dev/null); do
  file_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  if [ "$file_mtime" -ge "$FIVE_MIN_AGO" ]; then
    echo "$f"
    exit 0
  fi
done

# Nothing found
exit 0
