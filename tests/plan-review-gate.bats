#!/usr/bin/env bats

# Tests for scripts/plan-review-gate.sh
# Marker-based gate: checks plan for ## Decomplection Review and ## Risk Assessment.
# Risk level parsed from "Overall risk level: X" line in the plan.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/plan-review-gate.sh"

setup() {
  export CLAUDE_PROJECT_DIR="$(mktemp -d)"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/plans"
  # Override HOME so the script doesn't pick up real user plan files
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.claude/plans"
}

teardown() {
  rm -rf "$CLAUDE_PROJECT_DIR"
  rm -rf "$HOME"
}

create_plan() {
  local plan="$CLAUDE_PROJECT_DIR/.claude/plans/test-plan.md"
  printf '%s' "$1" > "$plan"
  echo "$plan"
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
}

# --- Plan missing only Risk Assessment: deny ---

@test "plan with decomplection but no risk — denies listing risk only" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll good')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "Risk Assessment"
}

# --- Plan missing only Decomplection: deny ---

@test "plan with risk but no decomplection — denies listing decomplection only" {
  create_plan "$(printf '# Plan\n## Risk Assessment\nOverall risk level: LOW')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"permissionDecision": "deny"'
  echo "$output" | grep -q "Decomplection Review"
}

# --- Both markers + LOW risk: allow ---

@test "both markers + LOW risk — allows through" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: LOW')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + NONE risk: allow ---

@test "both markers + NONE risk — allows through" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: NONE')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + ACCEPTED: allow ---

@test "both markers + ACCEPTED — allows through" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: ACCEPTED')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Case insensitive risk level ---

@test "both markers + lowercase 'low' — allows through" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: low')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Both markers + LOW risk + issue stack: outputs instruction ---

@test "both markers + LOW risk + issue stack — outputs PLAN APPROVED" {
  echo "- #42 — test issue (do)" > "$CLAUDE_PROJECT_DIR/.claude/issue-stack.md"
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: LOW')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "PLAN APPROVED"
  echo "$output" | grep -q "#42"
}

# --- Both markers + HIGH risk: deny with escalation ---

@test "both markers + HIGH risk — denies with RISKS REMAIN" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: HIGH')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RISKS REMAIN (HIGH)"
}

# --- Both markers + MEDIUM risk: deny ---

@test "both markers + MEDIUM risk — denies with RISKS REMAIN" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: MEDIUM')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RISKS REMAIN (MEDIUM)"
}

# --- Both markers but no Overall risk level line: deny ---

@test "both markers but no risk level line — denies with RISK LEVEL MISSING" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nSome analysis but no summary line')"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RISK LEVEL MISSING"
}

# --- Deny outputs are valid JSON ---

@test "missing markers — output is valid JSON" {
  create_plan "# Plan"
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "HIGH risk — output is valid JSON" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nOverall risk level: HIGH')"
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "missing risk level — output is valid JSON" {
  create_plan "$(printf '# Plan\n## Decomplection Review\nAll pass\n## Risk Assessment\nNo summary')"
  run bash "$SCRIPT"
  echo "$output" | python3 -m json.tool > /dev/null
}
