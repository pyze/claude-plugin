#!/usr/bin/env bats

# Tests for scripts/tdd-gate.sh
# PreToolUse advisory TDD check during pdca:do phase.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/tdd-gate.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
}

# --- No issue stack: silent ---

@test "no issue stack — silent" {
  export CLAUDE_TOOL_INPUT='{"file_path": "/src/foo.clj", "content": "(ns foo)"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Empty issue stack: silent ---

@test "empty issue stack — silent" {
  touch "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  export CLAUDE_TOOL_INPUT='{"file_path": "/src/foo.clj", "content": "(ns foo)"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- No issue number: silent ---

@test "no issue number — silent" {
  echo "- some note" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  export CLAUDE_TOOL_INPUT='{"file_path": "/src/foo.clj", "content": "(ns foo)"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- No file path in tool input: silent ---

@test "no file_path in tool input — silent" {
  echo "- #99 — test issue (do)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  export CLAUDE_TOOL_INPUT='{"content": "(ns foo)"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Non-Clojure file: silent ---

@test "non-Clojure file — silent" {
  echo "- #99 — test issue (do)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  export CLAUDE_TOOL_INPUT='{"file_path": "/src/readme.md", "content": "# Hello"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Test file: silent (always allowed) ---

@test "test file — silent" {
  echo "- #99 — test issue (do)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  export CLAUDE_TOOL_INPUT='{"file_path": "/test/foo_test.clj", "content": "(ns foo-test)"}'
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
