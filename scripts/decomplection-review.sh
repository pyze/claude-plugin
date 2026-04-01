#!/bin/bash
set -euo pipefail

# Decomplection review gate — runs on ExitPlanMode.
# First call: denies and asks for decomplection review.
# Second call: allows through (review presumed done).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/plan-gate.sh"

plan_gate "decomplection" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "DECOMPLECTION REVIEW REQUIRED\n\nBefore finalizing this plan, read the decomplection-first-design skill and evaluate each plan deliverable against its Implementation Checklist and Summary criteria.\n\nIf ANY criterion fails, revise the plan to decomplect before calling ExitPlanMode again.\nIf ALL criteria pass, call ExitPlanMode again to proceed."
  }
}'
