# pyze-claude-plugin (Deprecated)

> **This plugin has been split into focused, composable plugins.** Install the successors instead.

pyze-claude-plugin combined workflow infrastructure, Clojure development skills, and coding standards into a single package. As the plugin grew, the coupling between language-agnostic workflow and Clojure-specific tooling made it harder to use for non-Clojure projects and harder to maintain.

It has been replaced by three focused plugins:

| Plugin | Purpose |
|--------|---------|
| [pyze-workflow](https://github.com/pyze/pyze-workflow) | Language-agnostic workflow discipline: PDCA cycle, risk assessment, decomplection, TDD gates |
| [pyze-clojure](https://github.com/pyze/pyze-clojure) | Clojure/ClojureScript skills: coding standards, REPL workflows, Integrant, Pathom, Replicant |
| [pyze-python](https://github.com/pyze/pyze-python) | Python companion skills: pytest patterns, `@lru_cache` correctness, exception chaining |

## Migration

1. Remove the legacy plugin:
   ```bash
   claude plugin remove claude-plugin@pyze-plugins
   ```

2. Install the replacements:
   ```bash
   claude plugin add pyze/pyze-workflow
   # Then add your language companion:
   claude plugin add pyze/pyze-clojure   # for Clojure projects
   claude plugin add pyze/pyze-python    # for Python projects
   ```

3. Clear the cached legacy plugin to avoid hook conflicts:
   ```bash
   rm -rf ~/.claude/plugins/cache/pyze-plugins/claude-plugin
   ```

4. Restart Claude Code.

## What moved where

| Legacy skill/command | New home |
|---------------------|----------|
| pdca-cycle, risk-assessment, decomplection-first-design, testing-patterns, error-handling-patterns, caching-and-purity, bdd-scenarios, tool-selection, specification-first-development, documentation-maintenance, learning-capture, pr-document, formal-verification | [pyze-workflow](https://github.com/pyze/pyze-workflow) |
| /pdca, /align-docs, /arch-purity, /code-cleanup, /derisk, /five-whys | [pyze-workflow](https://github.com/pyze/pyze-workflow) |
| clojure-coding-standards, clojure-mcp-repl, integrant-lifecycle, pathom3-eql, replicant-ui, shadow-cljs, rewrite-clj-transforms, and all other Clojure skills | [pyze-clojure](https://github.com/pyze/pyze-clojure) |
| PDCA hooks, TDD gate, turn review, plan-to-issue | [pyze-workflow](https://github.com/pyze/pyze-workflow) |
| nREPL hint, mutable state warning | [pyze-clojure](https://github.com/pyze/pyze-clojure) |

## License

MIT
