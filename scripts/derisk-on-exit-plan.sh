#!/bin/bash
set -euo pipefail

# Derisk gate — runs on ExitPlanMode.
# First call: denies and instructs Claude to run /derisk loop.
# Second call: allows through (derisking presumed done).

# Find the most recent plan file
PLAN_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
PLAN_FILE=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ]; then
  # No plan file found — allow through
  exit 0
fi

# Marker file: hash of plan file path for uniqueness
MARKER_DIR="/tmp/claude-derisk-review"
mkdir -p "$MARKER_DIR"
PLAN_HASH=$(echo "$PLAN_FILE" | shasum -a 256 | cut -d' ' -f1)
MARKER_FILE="$MARKER_DIR/$PLAN_HASH"

if [ -f "$MARKER_FILE" ]; then
  # Already derisked — allow and clean up
  rm -f "$MARKER_FILE"
  exit 0
fi

# First attempt — create marker and deny with derisk instructions
touch "$MARKER_FILE"

cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DERISK REQUIRED\n\nBefore finalizing this plan, run /derisk to identify and validate unvalidated assumptions.\n\nLoop until ALL risks are LOW or further derisking is not possible:\n1. Identify unvalidated assumptions in the plan\n2. Validate critical assumptions at the REPL\n3. If a risk cannot be reduced, document why\n4. If any HIGH risks remain that cannot be derisked, STOP and ask the user for guidance\n\nWhen all risks are LOW (or user has approved remaining risks), call ExitPlanMode again."
  }
}
ENDJSON
