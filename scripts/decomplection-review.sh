#!/bin/bash
set -euo pipefail

# Decomplection review gate — runs on ExitPlanMode.
# First call: denies and asks for decomplection review.
# Second call: allows through (review presumed done).

# Find the most recent plan file
PLAN_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
PLAN_FILE=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ]; then
  # No plan file found — allow through
  exit 0
fi

# Marker file: hash of plan file path for uniqueness
MARKER_DIR="/tmp/claude-decomplection-review"
mkdir -p "$MARKER_DIR"
PLAN_HASH=$(echo "$PLAN_FILE" | shasum -a 256 | cut -d' ' -f1)
MARKER_FILE="$MARKER_DIR/$PLAN_HASH"

if [ -f "$MARKER_FILE" ]; then
  # Already reviewed — allow and clean up
  rm -f "$MARKER_FILE"
  exit 0
fi

# First attempt — create marker and deny with review criteria
touch "$MARKER_FILE"

cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DECOMPLECTION REVIEW REQUIRED\n\nBefore finalizing this plan, read the decomplection-first-design skill and evaluate each plan deliverable against its Implementation Checklist and Summary criteria.\n\nIf ANY criterion fails, revise the plan to decomplect before calling ExitPlanMode again.\nIf ALL criteria pass, call ExitPlanMode again to proceed."
  }
}
ENDJSON
