# Pyze Claude Plugin

Claude Code plugin providing Clojure development skills, coding standards, and workflow automation.

## Project Structure
- `skills/` - Skill definitions (SKILL.md files with frontmatter)
- `commands/` - Slash commands (markdown with YAML frontmatter)
- `hooks/` - Hook configurations (hooks.json)
- `agents/` - Agent definitions
- `scripts/` - Shell scripts used by hooks
- `.claude-plugin/plugin.json` - Plugin manifest

## Testing Changes
- Start a new Claude Code session to test skill/command/hook changes
- Use `/reload-plugins` to reload without restarting

## Halt on Violated Assumptions
When implementing a plan, if you discover that an assumption is wrong (reference implementation works differently, dependency behaves differently, data shape doesn't match) — **STOP immediately**. Do not note it and continue. Do not adapt. Report what you found and return to planning. See `pdca-cycle` skill for full details.

## Contributing
- Semver: major (breaking renames/removals), minor (new skills/hooks), patch (content fixes)
