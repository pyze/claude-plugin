---
name: repl-driven-development
description: Follow REPL-driven development workflow phases. Use when building features incrementally, testing assumptions, or integrating with TDD.
---

# REPL-Driven Development Skill

Build incrementally with immediate feedback. REPL for exploration, TDD for implementation.

**Primary tool**: clojure_eval (MCP tool). See [clojure-mcp-repl](../clojure-mcp-repl/) for complete reference.

## Core Principle: REPL for Exploration, TDD for Implementation

```
┌─────────────────────────────────────────────────────────────────┐
│  REPL-DRIVEN DEVELOPMENT IS MANDATORY                            │
│  TDD IS MANDATORY                                                │
│                                                                   │
│  Explore at REPL → Write failing test → Implement → Refactor    │
└─────────────────────────────────────────────────────────────────┘
```

**REPL exploration**: Understand existing code, discover data shapes, experiment with approaches, debug live state.

**TDD implementation**: Write failing test first, then minimal code to pass. Tests can be written and executed at the REPL.

```clojure
;; TDD at the REPL using clojure_eval MCP tool
(deftest test-my-fn (is (= 42 (my-fn 21))))
(test-my-fn)    ; See it FAIL
(defn my-fn [x] (* x 2))
(test-my-fn)    ; See it PASS
```

---

## Skill Boundary

This skill covers: **Workflow philosophy** - when to explore vs implement, 13-phase methodology.

**Use DIFFERENT skill if:**
- clojure_eval MCP tool mechanics → [clojure-mcp-repl](../clojure-mcp-repl/)
- TDD workflow details → `superpowers:test-driven-development`

## When to Use This Skill

**Use THIS skill if**:
- Learning the REPL-driven workflow methodology
- Deciding which phase of development you're in
- Understanding when to explore vs implement

---

## Phase 0: Brainstorming (Recommended)

Before entering Phase 1, consider using `superpowers:brainstorming` to explore WHAT to build. This is especially valuable when requirements are unclear or multiple approaches exist.

---

## Quick Reference: 13 Phases

| Phase | Name | Goal | Key Activities |
|-------|------|------|----------------|
| **1** | Specify | Define requirements | Write specs, create examples |
| **2** | Research | Gather technical context | Test libraries at REPL, discover constraints |
| **3** | Explore | Understand problem space | Load namespaces, examine data |
| **4** | Validate | Test assumptions | Edge cases, error handling |
| **5** | Design | Create solution plan | Choose data structures, design signatures |
| **6** | Develop | Build incrementally | Code at REPL, test immediately |
| **7** | JVM Unit Tests | Validate in production | Run tests for namespace |
| **8** | Browser Validation | Test in real browser | Verify DOM, events, async |
| **9** | Critique | Review implementation | Check spec alignment |
| **10** | Build | Compose components | Higher-level functions |
| **11** | Edit | Refine and polish | Remove complexity, improve naming |
| **12** | Verify | Ensure compliance | Write tests, run suite |
| **13** | Code Quality | Catch syntax issues | Run clj-kondo, fix warnings |

---

## Quick Decision

**Use compressed cycle if ALL of these apply**:
- [ ] Estimated < 2 hours implementation time
- [ ] No uncertainty about approach
- [ ] No UI/browser involvement
- [ ] No external service integration
- [ ] Well-understood pattern (you've done similar before)

**Use full 13-phase cycle if ANY of these apply**:
- [ ] Production-ready feature visible to users
- [ ] Multiple components involved
- [ ] UI interactions or visual elements
- [ ] External service integration
- [ ] Unclear requirements or multiple approaches

### Phase Comparison

| Phase | Full Cycle | Compressed |
|-------|:----------:|:----------:|
| 1. Specify | yes | yes (brief) |
| 2. Research | yes | Skip |
| 3. Explore | yes | yes |
| 4. Validate | yes | Skip |
| 5. Design | yes | Skip |
| 6. Develop | yes | yes |
| 7. JVM Unit Tests | yes | yes |
| 8. Browser Validation | yes | Skip |
| 9. Critique | yes | Skip |
| 10. Build | yes | Skip |
| 11. Edit | yes | yes (if needed) |
| 12. Verify | yes | yes |
| 13. Code Quality | yes | yes |

**Compressed cycle**: Specify -> Explore -> Develop -> Tests -> Lint (~5 phases)

---

## Development Environment Setup

### MANDATORY: Use clojure_eval for All REPL Interaction

**CRITICAL**: Use the clojure_eval MCP tool for all REPL evaluation. It connects to existing nREPL automatically.

```
┌─────────────────────────────────────────────────────────────────┐
│  ALWAYS use clojure_eval MCP tool to evaluate code              │
│  NEVER start interactive REPL sessions manually                  │
└─────────────────────────────────────────────────────────────────┘
```

### Setup: Enable REPL Connection

Ensure your project has an nREPL server running and a `.nrepl-port` file. Verify connectivity:
```clojure
;; Use clojure_eval MCP tool
(+ 1 2)
;; Expected: 3
```

### Which Context to Use?

```
What are you testing?
       │
       ├─ Backend code, services, Ring handlers → JVM context (default)
       │     Use clojure_eval MCP tool: (my.namespace/my-fn arg1 arg2)
       │
       ├─ ClojureScript, DOM, browser events → Browser context
       │     Use clojure_eval MCP tool: (shadow/repl :app)
       │     Then: (your-cljs-code)
       │
       └─ Uncertain? Check if code uses:
             ├─ js/* or .cljs extension → Browser context
             └─ JVM libs or .clj extension → JVM context
```

### Primary Patterns

```clojure
;; Use clojure_eval MCP tool for all evaluation

;; Function invocation
(my.namespace/my-fn arg1 arg2)
(+ 1 2 3)

;; Requiring namespaces
(require '[my.app.store :as store])

;; Dereferencing atoms
@my.ns/my-atom

;; Helper commands
(dir my.namespace)           ; List vars
(source my.ns/my-fn)        ; Show source
(doc my.ns/my-fn)           ; Show docs
```

### System Management (integrant-repl)

See [integrant-lifecycle skill](../integrant-lifecycle/) for complete details.

Uses integrant-repl for hot reloading. **`reset` is the key command** - it reloads changed namespaces before restarting.

```clojure
;; Use clojure_eval MCP tool

;; Start backend
(in-ns 'user)
(go)

;; Stop backend
(in-ns 'user)
(halt)

;; PREFERRED: Reload changed code + restart (no JVM restart needed)
(in-ns 'user)
(reset)

;; Full reload (use if reset fails, e.g., protocol/deftype changes)
(in-ns 'user)
(reset-all)
```

**When to use each**:
| Scenario | Command |
|----------|---------|
| Changed handler/route code | `reset` |
| Changed Integrant init-key | `reset` |
| Changed protocol/defrecord | `reset-all` |
| Added new dependency | Restart JVM |

### Anti-Patterns (NEVER DO THESE)

```bash
# WRONG: Starting interactive REPL sessions
clj -M:dev              # NO - use clojure_eval MCP tool instead
lein repl               # NO - use clojure_eval MCP tool instead

# CORRECT: Always use clojure_eval MCP tool
# Example: (my.namespace/my-fn arg1)
```

---

## Additional Resources

- [PHASE_GUIDE.md](./PHASE_GUIDE.md) - Detailed checklists for all 13 phases
- [PATTERNS.md](./PATTERNS.md) - Common patterns and anti-patterns

---

## Summary

**Key Principle**: REPL-driven development catches issues early. Test immediately, refine continuously, compose from validated pieces.
