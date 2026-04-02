#!/usr/bin/env bats

# Tests for scripts/plan-review-gate.sh
# Marker-based gate: checks plan for ## Decomplection Review and ## Risk Assessment.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/plan-review-gate.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/plans"
  rm -rf /tmp/claude-derisk-result
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
  rm -rf /tmp/claude-derisk-result
}

create_plan() {
  local plan="$CLAUDE_PROJECT_DIR/.claude/plans/test-plan.md"
  echo "$1" > "$plan"
  echo "$plan"
}

result_file_for() {
  local plan="$1"
  local hash
  hash=$(echo "$plan" | shasum -a 256 | cut -d' ' -f1)
  echo "/tmp/claude-derisk-result/$hash"
}

# --- No plan file: allow through ---

@test "no plan file — allows through" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Plan missing both markers: deny ---

@test "plan missing both markers — denies with PLAN REVIEW REQUIRED" {
  create_plan "# My Plan"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "PLAN REVIEW REQUIRED"
  echo "$output" | grep -q "Decomplection Review"
  echo "$output" | grep -q "Risk Assessment"
}

# --- Plan missing only Risk Assessment: deny listing one ---

@test "plan with decomplection but no risk — denies listing risk only" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll good')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "Risk Assessment"
}

# --- Plan missing only Decomplection: deny listing one ---

@test "plan with risk but no decomplection — denies listing decomplection only" {
  create_plan "$(printf '# Plan\n## Risk Assessment\nLOW')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "Decomplection Review"
}

# --- Both markers + LOW risk: allow ---

@test "both markers + LOW risk — allows through" {
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nLOW')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "LOW" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + NONE risk: allow ---

@test "both markers + NONE risk — allows through" {
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nNONE')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "NONE" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + ACCEPTED: allow ---

@test "both markers + ACCEPTED — allows through" {
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nACCEPTED')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "ACCEPTED" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + LOW risk + issue stack: outputs instruction ---

@test "both markers + LOW risk + issue stack — outputs PLAN APPROVED with issue number" {
  echo "- #42 — test issue (do)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nLOW')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "LOW" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "PLAN APPROVED"
  echo "$output" | grep -q "#42"
  echo "$output" | grep -q "gh issue view"
}

# --- Both markers + HIGH risk: deny with escalation ---

@test "both markers + HIGH risk — denies with RISKS REMAIN" {
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nHIGH')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "HIGH" > "$rf"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RISKS REMAIN (HIGH)"
}

# --- Both markers + no result file: deny ---

@test "both markers + no result file — denies with DERISK RESULT MISSING" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nLOW')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "DERISK RESULT MISSING"
}

# --- Deny outputs are valid JSON ---

@test "missing markers — output is valid JSON" {
  create_plan "# Plan"
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "HIGH risk — output is valid JSON" {
  local plan
  plan=$(create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nHIGH')")
  local rf
  rf=$(result_file_for "$plan")
  mkdir -p "$(dirname "$rf")"
  echo "HIGH" > "$rf"

  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}
