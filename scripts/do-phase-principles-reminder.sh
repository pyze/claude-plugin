#!/bin/bash
set -euo pipefail

# PreCompact hook — re-injects coding principles so they survive context compression.
# Only fires during pdca:do phase. Silent otherwise.

STACK="${CLAUDE_PROJECT_DIR:-.}/.claude/issue-stack.md"
[ -f "$STACK" ] || exit 0

ISSUE=$(grep '^- #' "$STACK" | head -1 | grep -o '#[0-9]*' | tr -d '#' || true)
[ -n "$ISSUE" ] || exit 0

LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' 2>/dev/null || true)
echo "$LABELS" | grep -q 'pdca:do' || exit 0

cat <<'EOF'
=== DO-PHASE PRINCIPLES (survive into compressed context) ===
1. TDD: Write/update test BEFORE implementation. No src/ edit without test/ edit first.
2. FAIL-FAST: Fix the SOURCE. Never (or x default) for missing data. Never keep old code paths alive during refactoring. Cut over cleanly.
3. DECOMPLECT: All deps explicit as args. No hidden state. One concern per fn. Ask before atom/ref.
===
EOF
