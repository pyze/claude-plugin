#!/bin/bash
set -euo pipefail

# Shared logic for plan-gate hooks (decomplection-review, derisk).
# First call: denies with a message. Second call: allows through.
#
# Usage: source this file, then call plan_gate "gate-name" "deny reason JSON"
#   gate-name: unique identifier for the marker directory (e.g. "decomplection", "derisk")
#   deny_json: the full JSON hookSpecificOutput to emit on first call

plan_gate() {
  local gate_name="$1"
  local deny_json="$2"

  # Find the most recent plan file
  local plan_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
  local plan_file
  plan_file=$(ls -t "$plan_dir"/*.md 2>/dev/null | head -1 || true)

  if [ -z "$plan_file" ]; then
    # No plan file found — allow through
    exit 0
  fi

  # Marker file: hash of plan file path for uniqueness
  local marker_dir="/tmp/claude-${gate_name}-review"
  mkdir -p "$marker_dir"
  local plan_hash
  plan_hash=$(echo "$plan_file" | shasum -a 256 | cut -d' ' -f1)
  local marker_file="$marker_dir/$plan_hash"

  if [ -f "$marker_file" ]; then
    # Already reviewed — allow and clean up
    rm -f "$marker_file"
    exit 0
  fi

  # First attempt — create marker and deny
  touch "$marker_file"
  echo "$deny_json"
}
