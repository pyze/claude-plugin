#!/bin/bash
set -euo pipefail

# PreToolUse hook for Edit and Write — advisory TDD check during pdca:do.
# Warns if editing a source file when no test files have been modified yet.

STACK="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"
[ -f "$STACK" ] || exit 0

ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)
[ -n "$ISSUE" ] || exit 0

LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' 2>/dev/null || true)
echo "$LABELS" | grep -q 'pdca:do' || exit 0

# Extract file path from tool input
FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)
[ -n "$FILE_PATH" ] || exit 0

# Test files are always allowed without comment
if echo "$FILE_PATH" | grep -qE '(_test\.clj|_test\.cljs|_test\.cljc|/test/)'; then
  exit 0
fi

# Only check Clojure source files
echo "$FILE_PATH" | grep -qE '\.(clj|cljs|cljc)$' || exit 0

# Check if any test files have been modified in working tree
cd "$CLAUDE_PROJECT_DIR"
TEST_CHANGES=$(git diff --name-only HEAD 2>/dev/null | grep -cE '(_test\.clj|_test\.cljs|_test\.cljc|/test/)' || true)

if [ "${TEST_CHANGES:-0}" -eq 0 ]; then
  echo 'TDD CHECK: No test files modified yet. Write/update the test BEFORE implementation. If this is config/docs/refactor, proceed.'
fi
