#!/usr/bin/env bash
# Check if allium@juxt-plugins is enabled in Claude Code settings.
# Prints an install prompt if missing. Exits silently if installed.
settings="$HOME/.claude/settings.json"
if [[ -f "$settings" ]] && grep -q '"allium@juxt-plugins"' "$settings"; then
  exit 0
fi
echo "=== allium not installed ==="
echo "allium is a standard companion for pyze-workflow. Install with:"
echo "  claude plugin add allium@juxt-plugins"
