#!/bin/bash
# Stop hook — compare git state against turn-start snapshot.
# Produces targeted reminders based on what actually changed during the turn.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Find the snapshot from turn start
SNAPSHOT_PATH_FILE="/tmp/claude-turn-snapshot-path"
[ -f "$SNAPSHOT_PATH_FILE" ] || exit 0
SNAPSHOT=$(cat "$SNAPSHOT_PATH_FILE")
[ -f "$SNAPSHOT.files" ] || exit 0

# Get current changed files
git diff --name-only HEAD 2>/dev/null > /tmp/claude-turn-current-files || true

# Compute files changed during THIS turn (new changes not in snapshot)
new_changes=$(comm -13 <(sort "$SNAPSHOT.files") <(sort /tmp/claude-turn-current-files) 2>/dev/null || true)

# Clean up snapshot
rm -f "$SNAPSHOT.files" "$SNAPSHOT.ts" "$SNAPSHOT_PATH_FILE" /tmp/claude-turn-current-files

reminders=""

# --- File-change-based reminders (only if something changed) ---
if [ -n "$new_changes" ]; then
  src_changed=$(echo "$new_changes" | grep -E '^src/' || true)
  test_changed=$(echo "$new_changes" | grep -E '^test/' || true)

  # TDD check: src/ changed without test/
  if [ -n "$src_changed" ] && [ -z "$test_changed" ]; then
    src_count=$(echo "$src_changed" | wc -l | tr -d ' ')
    reminders="${reminders}TDD: ${src_count} source file(s) changed with no test files. Write tests first, not after.\n"
  fi
fi

# --- PDCA phase reminders (always check, regardless of file changes) ---
STACK="${CLAUDE_PROJECT_DIR}/.claude/issue-stack.md"
if [ -f "$STACK" ]; then
  ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)
  if [ -n "$ISSUE" ]; then
    LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' 2>/dev/null || true)

    if echo "$LABELS" | grep -q 'pdca:do'; then
      if [ -n "$new_changes" ]; then
        total_changed=$(echo "$new_changes" | wc -l | tr -d ' ')
        if [ "$total_changed" -ge 3 ]; then
          reminders="${reminders}Issue #${ISSUE}: ${total_changed} files changed this turn. Update the issue with progress.\n"
        fi
      fi
    fi

    if echo "$LABELS" | grep -q 'pdca:check'; then
      reminders="${reminders}Issue #${ISSUE}: Check phase — record learnings before moving on.\n"
    fi

    if echo "$LABELS" | grep -q 'pdca:react'; then
      reminders="${reminders}Issue #${ISSUE}: React phase — ensure the user has responded to the gap analysis.\n"
    fi
  fi
fi

# Output reminders (if any)
if [ -n "$reminders" ]; then
  printf "=== Turn Review ===\n${reminders}==="
fi
