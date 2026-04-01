#!/usr/bin/env bats

# Tests for scripts/block-local-plans.sh
# Blocks all Write calls during pdca:plan phase.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/block-local-plans.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
}

# --- No issue stack: allow through ---

@test "no issue stack file — allows through" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Empty issue stack: allow through ---

@test "empty issue stack — allows through" {
  touch "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Issue stack with no matching issue format ---

@test "issue stack with no issue number — allows through" {
  echo "- some note without issue number" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}
