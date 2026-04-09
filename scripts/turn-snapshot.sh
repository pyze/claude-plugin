#!/bin/bash
# UserPromptSubmit hook — snapshot git state at turn start.
# The Stop hook (turn-review.sh) diffs against this to detect what changed.

SNAPSHOT="/tmp/claude-turn-snapshot-$$"

# Save current git status (short format) and timestamp
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

# Only snapshot if we're in a git repo
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

git diff --name-only HEAD 2>/dev/null > "$SNAPSHOT.files" || true
echo "$(date +%s)" > "$SNAPSHOT.ts"

# Store the snapshot path for the Stop hook to find
echo "$SNAPSHOT" > /tmp/claude-turn-snapshot-path

echo "OK"
