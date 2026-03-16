#!/usr/bin/env bash
# Hook: PreToolUse on ExitPlanMode
# Reminds Claude to review project principles before finalizing a plan.

cat <<'EOF'
PRINCIPLES CHECK: Before finalizing this plan, re-read the Principles
section in CLAUDE.md. For each principle, verify the plan does not
violate it — especially in migration strategies, fallback mechanisms,
and coexistence of old/new code paths.
EOF
