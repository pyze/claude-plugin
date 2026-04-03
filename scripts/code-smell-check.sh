#!/bin/bash
set -euo pipefail

# PostToolUse:Edit hook — check for code smells in edited content.
# All smells are treated uniformly: warn with the pattern name and a pointer to docs.
# Add new smells by adding a check_smell call below.

INPUT="$CLAUDE_TOOL_INPUT"
warnings=""

check_smell() {
  local pattern="$1"
  local label="$2"
  local doc="$3"
  local skip_if_approved="${4:-false}"

  if echo "$INPUT" | grep -qE "$pattern"; then
    if [ "$skip_if_approved" = "true" ] && echo "$INPUT" | grep -qi 'APPROVED'; then
      return
    fi
    warnings="${warnings}
- ${label} (see ${doc})"
  fi
}

# --- Code smells ---
check_smell '\(atom |\(volatile! |\(ref |\(agent |\(defonce ' \
  'Mutable state (atom/volatile!/ref/agent) — requires user approval' \
  'clojure-coding-standards' \
  'true'

check_smell 'requestAnimationFrame|js/requestAnimationFrame' \
  'requestAnimationFrame — data flow problem, not timing' \
  'replicant-ui LIFECYCLE.md'

check_smell 'setTimeout|js/setTimeout' \
  'setTimeout for state sync — masks race condition' \
  'FUNCTIONAL-PRINCIPLES.md'

check_smell 'with-redefs' \
  'with-redefs — fix composition model, make dependency explicit' \
  'FUNCTIONAL-PRINCIPLES.md'

check_smell 'alter-var-root' \
  'alter-var-root — global mutation, use Integrant or protocols' \
  'FUNCTIONAL-PRINCIPLES.md'

check_smell '\(declare ' \
  'declare — reorder functions or extract to separate namespace' \
  'CODE-ORGANIZATION.md'

# --- Output ---
if [ -n "$warnings" ]; then
  echo "CODE SMELL WARNING:${warnings}"
fi
