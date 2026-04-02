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

<!-- BEGIN GENERATED CATALOG -->
## Skills

| Skill | Description |
|-------|-------------|
| `bdd-scenarios` | Convert specification examples into executable Given/When/Then scenarios using clojure.test |
| `caching-and-purity` | Reason correctly about caching and referential transparency |
| `clojure-coding-standards` | Comprehensive Clojure code quality standards including functional programming principles, code organization guidelines, and collection transformation patterns - use for writing maintainable, testable, and performant Clojure code |
| `clojure-mcp-repl` | Execute Clojure/ClojureScript code at the REPL using clojure-mcp (MCP server) |
| `clojurescript-cross-platform-code` | Write cross-platform ClojureScript code for JVM TDD |
| `clojurescript-shadow-cljs` | Build ClojureScript with Shadow-CLJS compilation and hot reload |
| `continuous-eql` | Continuous EQL — Missionary Signal Graph Architecture |
| `decomplection-first-design` | Apply simple-over-easy design philosophy |
| `documentation-maintenance` | Follow documentation placement and maintenance guidelines |
| `error-handling-patterns` | Design error handling with fail-fast philosophy, Truss assertions, and Telemere structured logging |
| `gemini-sdk-clojure` | Use when writing Clojure code that calls the Google Gemini Java SDK (com.google.genai), adding function declarations, building schemas, handling function calls, or debugging varargs interop errors |
| `integrant-lifecycle` | Manage system lifecycle with Integrant dependency injection |
| `learning-capture` | Decide when and where to persist learnings |
| `nucleus-notation` | Encode behavioral directives and data models using mathematical symbols for compressed AI prompts |
| `pathom3-eql` | Build EQL resolvers with Pathom 3 for data resolution |
| `pdca-cycle` | Plan-Do-Check-React cycle for complex work |
| `pr-document` | Use when preparing a pull request, filling out the PR template, or when the user says /pr-document |
| `pyramid-state-management` | Manage normalized state with Pyramid |
| `reitit-routing` | Configure server and client routing with Reitit |
| `repl-driven-development` | Follow REPL-driven development workflow |
| `repl-semantic-search` | Use REPL introspection as semantic search over Clojure codebases |
| `replicant-ui` | Build UI components with Replicant vDOM and hiccup syntax |
| `rewrite-clj-transforms` | Structural Clojure code modification via bb + rewrite-clj |
| `specification-first-development` | Write specifications before code to clarify requirements |
| `wemble-gemini` | Use when using Wemble's Gemini integration - client lifecycle, chat-turn, ask/ask-json/ask-text, tool data maps, context caching, ->schema DSL, and schema compatibility validation |

## Commands

| Command | Description |
|---------|-------------|
| `/align-docs` | Proactive documentation audit for ambiguities and conflicts |
| `/arch-purity` | Architectural gap analysis: validate code against declared architecture |
| `/code-cleanup` | Static analysis for Clojure code quality violations |
| `/derisk` | Risk analysis: identify options, validate assumptions at REPL |
| `/execute` | Execute an implementation plan from a GitHub issue |
| `/five-whys` | Root cause analysis for Claude mistakes via why chain |
<!-- END GENERATED CATALOG -->

## Hooks (v4.0)

The plugin provides hooks for PDCA workflow automation and do-phase principle reinforcement:

| Hook | Event | Purpose |
|------|-------|---------|
| PDCA plan transition | `PreToolUse:EnterPlanMode` | Transition issue to `pdca:plan`, explain required plan sections |
| Plan to issue | `PreToolUse:ExitPlanMode` | Require active GitHub issue, auto-post plan as comment (backgrounded) |
| Plan review gate | `PreToolUse:ExitPlanMode` | Check for `## Decomplection Review` and `## Risk Assessment` markers; verify derisk result |
| Block writes in plan mode | `PreToolUse:Write` | Block file writes during `pdca:plan` (except `.claude/plans/`) |
| TDD gate | `PreToolUse:Edit\|Write` | Advisory: warn when editing source files with no test files modified yet (do phase only) |
| REPL hint | `PreToolUse:Grep` | Suggest REPL for structural queries when nREPL is running |
| Git commit reminder | `PostToolUse:Bash` | Remind to update issue stack on commit |
| Issue creation reminder | `PostToolUse:Bash` | Remind that issue body = problem statement |
| PDCA phase transition | `PostToolUse:Task` | Prompt Check phase when Do tasks complete |
| Mutable state detection | `PostToolUse:Edit` | Warn on unapproved atom/volatile!/ref/agent introduction |
| Assumption violation check | `SubagentStop` | Prompt-based: evaluate if subagent deviated from plan due to unexpected conditions |
| Principles survival | `PreCompact` | Re-inject TDD/fail-fast/decomplection/assumptions before context compression (do phase only) |
| Issue stack on notification | `Notification` | Show issue stack breadcrumb |
| PDCA stop check | `Stop` | Check PDCA phase and prompt next action |
| Issue stack on start | `SessionStart` | Show current issue stack at session start |

## Agents (v2.0)

| Agent | Description |
|-------|-------------|
| `issue-listener` | Monitors GitHub issues for new comments, posts `[claude-response]` replies |

## Scripts (v4.0)

| Script | Purpose |
|--------|---------|
| `pdca-plan-on-enter-plan-mode.sh` | PDCA label transition + explain required plan sections |
| `plan-to-issue.sh` | Auto-post plan to GitHub issue (backgrounded), block if no issue |
| `plan-review-gate.sh` | Marker-based gate: check for decomplection/risk sections + verify derisk result |
| `block-local-plans.sh` | Block file writes during `pdca:plan` (except `.claude/plans/`) |
| `do-phase-principles-reminder.sh` | PreCompact: re-inject TDD/fail-fast/decomplection/assumptions |
| `tdd-gate.sh` | Advisory TDD check: warn on source edits when no tests modified yet |
| `generate-readme-catalog.sh` | Generate Skills/Commands tables from frontmatter (`--update` to write to README) |
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
