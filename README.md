# Pyze Claude Code Plugin

Clojure development skills, coding standards, and workflow infrastructure for Claude Code.

## Installation

```bash
/plugin install claude-plugin@pyze-plugins
```

Or add to your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "claude-plugin@pyze-plugins": true
  }
}
```

## Skills

### Clojure Coding Standards
| Skill | Description |
|-------|-------------|
| `clojure-coding-standards` | Unified code quality: FP principles, organization, collections, idioms |
| `error-handling-patterns` | Fail-fast philosophy, Truss assertions, Telemere structured logging |
| `caching-and-purity` | Referential transparency, cache correctness, purity diagnostics |
| `decomplection-first-design` | Simple-over-easy philosophy, concern separation |

### ClojureScript & Build
| Skill | Description |
|-------|-------------|
| `clojurescript-cross-platform-code` | JVM TDD, .clj/.cljs/.cljc decision tree, reader conditionals |
| `clojurescript-shadow-cljs` | Shadow-CLJS configuration, hot reload, build targets |

### System Architecture
| Skill | Description |
|-------|-------------|
| `integrant-lifecycle` | System lifecycle, service naming (slash notation), Aero config |
| `reitit-routing` | Server and client routing, URL design, history behavior |

### Development Workflow
| Skill | Description |
|-------|-------------|
| `repl-driven-development` | 13-phase methodology, REPL exploration + TDD implementation |
| `clojure-mcp-repl` | clojure_eval MCP tool mechanics, nREPL connection, system management |
| `specification-first-development` | Specifications before code, 4-phase workflow |
| `bdd-scenarios` | Given/When/Then scenarios in clojure.test |
| `documentation-maintenance` | Documentation placement and maintenance guidelines |

### Design & Process
| Skill | Description |
|-------|-------------|
| `pr-document` | PR template co-authoring, review dimensions |
| `nucleus-notation` | Mathematical prompting framework for compressed AI directives |

## Commands

| Command | Description |
|---------|-------------|
| `/five-whys` | Root cause analysis for Claude mistakes via why chain |
| `/align-docs` | Proactive documentation audit for ambiguities and conflicts |
| `/derisk` | Risk analysis: identify options, validate assumptions at REPL |

## Contributing

1. Fork `pyze/claude-plugin`
2. Clone locally
3. Edit skills/commands
4. Test by starting new Claude Code sessions
5. PR to `pyze/claude-plugin`

### Versioning

Semver: major (breaking skill renames/removals), minor (new skills), patch (content fixes).

## License

MIT
