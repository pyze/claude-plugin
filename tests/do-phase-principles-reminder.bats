#!/usr/bin/env bats

# Tests for scripts/do-phase-principles-reminder.sh
# PreCompact hook that re-injects principles during pdca:do phase.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/do-phase-principles-reminder.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
}

# --- No issue stack: silent ---

@test "no issue stack — silent" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Empty issue stack: silent ---

@test "empty issue stack — silent" {
  touch "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Issue stack with no issue number: silent ---

@test "no issue number in stack — silent" {
  echo "- some note" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
