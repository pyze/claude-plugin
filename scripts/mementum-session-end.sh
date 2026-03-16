#!/bin/bash
# Mementum session-end hook
# Reminds about memory creation if session was substantive

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

# Only show reminder if memories directory exists
if [ -d "memories" ]; then
    echo ""
    echo "=== Mementum Reminder ==="
    echo "If learning occurred this session, consider creating a memory."
    echo "See the mementum skill for usage details."
    echo ""
fi
