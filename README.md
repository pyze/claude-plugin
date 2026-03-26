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
| `repl-driven-development` | REPL exploration + TDD implementation (compressed 5-phase default, full 13-phase for complex features) |
| `clojure-mcp-repl` | clojure_eval MCP tool mechanics, nREPL connection, system management |
| `specification-first-development` | Specifications before code, 4-phase workflow |
| `bdd-scenarios` | Given/When/Then scenarios in clojure.test |
| `documentation-maintenance` | Documentation placement and maintenance guidelines |

### Design & Process
| Skill | Description |
|-------|-------------|
| `pdca-cycle` | Plan-Do-Check-React loop for complex work — phase transitions, gap analysis, lessons learned |
| `pr-document` | PR template co-authoring, review dimensions |
| `nucleus-notation` | Mathematical prompting framework for compressed AI directives |

### Learning & Search
| Skill | Description |
|-------|-------------|
| `learning-capture` | When and where to persist learnings (auto-memory vs skills vs CLAUDE.md) |
| `repl-semantic-search` | REPL introspection as semantic search over Clojure codebases |
| `rewrite-clj-transforms` | Structural code modification via bb + rewrite-clj (ns requires, EDN updates, bulk transforms) |

### Library-Specific Skills (v3.0)
| Skill | Description |
|-------|-------------|
| `pathom3-eql` | Pathom 3 resolver patterns, EQL queries, error handling, ident conventions |
| `replicant-ui` | Replicant vDOM, hiccup syntax, event handlers, lifecycle hooks, JS interop |
| `continuous-eql` | Missionary signal graph, reactive Pathom, MissionaryTask/Flow protocols |
| `pyramid-state-management` | Pyramid normalized store, entity identity, ident conventions |

## Commands

| Command | Description |
|---------|-------------|
| `/five-whys` | Root cause analysis for Claude mistakes via why chain |
| `/align-docs` | Proactive documentation audit for ambiguities and conflicts |
| `/derisk` | Risk analysis: identify options, validate assumptions at REPL |
| `/execute` | Execute an implementation plan from a GitHub issue |
| `/code-cleanup` | Static analysis for Clojure code quality violations |

## Hooks (v2.0)

The plugin provides hooks for PDCA workflow automation:

| Hook | Event | Purpose |
|------|-------|---------|
| PDCA plan transition | `PreToolUse:EnterPlanMode` | Transition issue to `pdca:plan`, print PDCA reminder |
| Principles check | `PreToolUse:ExitPlanMode` | Validate plan against project principles before execution |
| Decomplection review | `PreToolUse:ExitPlanMode` | Gate plan finalization with decomplection checklist |
| Derisk gate | `PreToolUse:ExitPlanMode` | Loop /derisk until all risks are LOW before execution |
| Block local plans | `PreToolUse:Write` | Prevent creating local plan files (forces GitHub Issues) |
| Issue stack display | `PreToolUse:Bash\|Task\|Edit` | Show current issue stack context |
| Git commit reminder | `PostToolUse:Bash` | Remind to update issue stack on commit |
| PDCA phase transition | `PostToolUse:Task` | Prompt Check phase when Do tasks complete |
| Issue stack on notification | `Notification` | Show issue stack breadcrumb |
| PDCA stop check | `Stop` | Check PDCA phase and prompt next action |
| Issue stack on start | `SessionStart` | Show current issue stack at session start |

## Agents (v2.0)

| Agent | Description |
|-------|-------------|
| `issue-listener` | Monitors GitHub issues for new comments, posts `[claude-response]` replies |

## Scripts (v2.0)

| Script | Purpose |
|--------|---------|
| `pdca-plan-on-enter-plan-mode.sh` | PDCA label transition + plan mode reminder |
| `plan-principles-check.sh` | Principles review before plan finalization |
| `block-local-plans.sh` | Prevent local plan file creation |
| `decomplection-review.sh` | Gate plan exit with decomplection checklist |
| `derisk-on-exit-plan.sh` | Loop /derisk until all risks are LOW before execution |
| `statusline.sh` | Status line showing issue stack, PDCA phase, model, context % |

## Status Line

The plugin ships a status line script. To enable, add to your project or user `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<path-to-plugin>/scripts/statusline.sh"
  }
}
```

**Displays:** `[Model] #52 (do) | 23% ctx | $1.45`

- Current model name
- Top issue from stack + PDCA phase
- Context window usage
- Session cost

## Project Setup Requirements

Projects using the workflow features (PDCA, issue stack) should create:

- `.claude/issue-stack.md` — Issue stack file (empty or with initial issues)

## Contributing

1. Fork `pyze/claude-plugin`
2. Clone locally
3. Edit skills/commands/hooks/scripts
4. Test by starting new Claude Code sessions
5. PR to `pyze/claude-plugin`

### Versioning

Semver: major (breaking skill renames/removals), minor (new skills/hooks), patch (content fixes).

## License

MIT
