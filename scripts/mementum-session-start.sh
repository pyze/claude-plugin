#!/bin/bash
# Mementum session-start hook
# Loads recent memories into context at session start

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

if [ -d "memories" ]; then
    echo "=== Recent Memories ==="
    git log -n 3 --pretty=format:"- %s" -- memories/ 2>/dev/null | head -10
    echo ""
fi
