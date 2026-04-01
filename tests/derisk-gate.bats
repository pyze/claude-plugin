#!/usr/bin/env bats

# Tests for scripts/derisk-on-exit-plan.sh
# The gate checks /tmp/claude-derisk-result/<plan-hash> for risk level.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/derisk-on-exit-plan.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/plans"

  # Clean result dir to avoid cross-test contamination
  rm -rf /tmp/claude-derisk-result
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
  rm -rf /tmp/claude-derisk-result
}

# Helper: create a plan file and return its result file path
create_plan() {
  local plan="$CLAUDE_PROJECT_DIR/.claude/plans/test-plan.md"
  echo "# Plan" > "$plan"
  echo "$plan"
}

result_file_for() {
  local plan="$1"
  local hash
  hash=$(echo "$plan" | shasum -a 256 | cut -d' ' -f1)
  echo "/tmp/claude-derisk-result/$hash"
}

# --- No plan file: allow through silently ---

@test "no plan file — allows through with no output" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Plan exists, no result file: deny ---

@test "plan exists, no result file — denies with DERISK REQUIRED" {
  create_plan
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "DERISK REQUIRED"
}

# --- LOW risk: allow through ---

@test "LOW risk — allows through with no output" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "LOW" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "LOW risk — cleans up result file" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "LOW" > "$rf"

  bash "$SCRIPT"
  [ ! -f "$rf" ]
}

# --- NONE risk: allow through ---

@test "NONE risk — allows through with no output" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "NONE" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- ACCEPTED: allow through ---

@test "ACCEPTED — allows through with no output" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "ACCEPTED" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Case insensitivity ---

@test "lowercase 'low' — allows through" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "low" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "mixed case 'Accepted' — allows through" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "Accepted" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- MEDIUM risk: deny and escalate ---

@test "MEDIUM risk — denies with RISKS REMAIN" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "MEDIUM" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "RISKS REMAIN (MEDIUM)"
}

@test "MEDIUM risk — cleans up result file" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "MEDIUM" > "$rf"

  bash "$SCRIPT"
  [ ! -f "$rf" ]
}

# --- HIGH risk: deny and escalate ---

@test "HIGH risk — denies with RISKS REMAIN" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "HIGH" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "RISKS REMAIN (HIGH)"
}

# --- Deny output is valid JSON ---

@test "no result file — output is valid JSON" {
  create_plan
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "HIGH risk — output is valid JSON" {
  local plan
  plan=$(create_plan)
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "HIGH" > "$rf"

  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

# --- Multiple plan files: uses most recent ---

@test "multiple plans — uses most recently modified" {
  # Create older plan
  echo "# Old" > "$CLAUDE_PROJECT_DIR/.claude/plans/old-plan.md"
  sleep 1
  # Create newer plan
  local newer="$CLAUDE_PROJECT_DIR/.claude/plans/new-plan.md"
  echo "# New" > "$newer"

  # Write LOW result for the newer plan only
  local rf
  rf=$(result_file_for "$newer")
  mkdir -p "$(dirname "$rf")"
  echo "LOW" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
