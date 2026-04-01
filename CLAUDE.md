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

## Contributing
- Semver: major (breaking renames/removals), minor (new skills/hooks), patch (content fixes)
