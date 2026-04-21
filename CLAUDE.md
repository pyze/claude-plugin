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

## Allium Specs

Allium `.allium` specs are authoritative behavioral documentation and must be kept current.

- **During planning:** If a spec contradicts the planned approach, invoke `allium:distill` to reconcile before proceeding. Do not plan around a stale spec.
- **During any other phase (Do, Check, React):** A spec/code contradiction is a bug — either the code is wrong or the spec is wrong. Stop immediately. If the code is wrong, fix it. If the spec is wrong, do not change it unilaterally — stop and get input from the user before updating the spec.

## Contributing
- Semver: major (breaking renames/removals), minor (new skills/hooks), patch (content fixes)
