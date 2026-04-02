#!/usr/bin/env bats

# Tests for scripts/plan-to-issue.sh
# ExitPlanMode hook: require GitHub issue + post plan in background.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/plan-to-issue.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
}

# --- No issue stack: deny ---

@test "no issue stack — denies with NO ACTIVE ISSUE" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "NO ACTIVE ISSUE"
}

# --- Empty issue stack: deny ---

@test "empty issue stack — denies with NO ACTIVE ISSUE" {
  touch "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

# --- Issue stack with no issue number: deny ---

@test "no issue number in stack — denies" {
  echo "- some note without number" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
}

# --- Deny output is valid JSON ---

@test "no issue stack — output is valid JSON" {
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

# --- Happy path: issue exists + plan file → allows through silently ---

@test "issue exists + plan file — allows through with no deny" {
  echo "- #42 — test issue (plan)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/plans"
  echo "# My Plan" > "$CLAUDE_PROJECT_DIR/.claude/plans/test-plan.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # Should NOT contain a deny
  ! echo "$output" | grep -q '"permissionDecision": "deny"'
}

# --- Happy path: issue exists + no plan file → allows through ---

@test "issue exists + no plan file — allows through" {
  echo "- #42 — test issue (plan)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
