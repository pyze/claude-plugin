# /code-cleanup

Analyze all code (including tests) for violations of Clojure best practices and opportunities for refactoring. Creates GitHub issues for follow-on cleanup tasks.

Uses clj-kondo for static analysis and identifies:
- **Dead code and unused bindings** - Unused functions, parameters, and local variables
- **Overly complex functions** - Functions exceeding recommended complexity levels
- **Violation of functional programming principles** - Unnecessary mutations, missing pure function patterns
- **Code duplication and abstraction opportunities** - Repeated patterns that could be extracted
- **Test code that could be simplified** - Verbose test fixtures or redundant assertions
- **Tests bypassing public API** - Test helpers using private functions or different execution paths than production code
- **Performance anti-patterns** - Inefficient operations, unnecessary allocations, reflection warnings

## How It Works

The command will:

1. **Launch parallel analysis agents** to search for violations across:
   - `src/` - Core implementation files
   - `test/` - All test files

2. **Detect violations** using clj-kondo static analysis plus manual pattern detection:
   - Reflection warnings (high priority - performance impact)
   - Unused imports and bindings (medium priority)
   - Complex functions (medium priority - maintainability)
   - Duplicate code patterns (low priority - refactoring opportunity)

3. **Create GitHub issues** organized by category with task-list checklists

## Usage

```bash
/code-cleanup
```

## Priority Levels

**High Priority:**
- Tests bypassing public API (tests must exercise production code paths)
- Unapproved `requiring-resolve` usage (lazy loading must be explicitly justified)
- Reflection warnings (can impact performance significantly)
- Unsafe resource handling
- Critical pattern violations

**Medium Priority:**
- Unused bindings (code clarity)
- Complex functions (maintainability)
- Dead code (technical debt)

**Low Priority:**
- Code duplication (refactoring opportunity)
- Test simplification (nice-to-have)

## Detection Patterns

### clj-kondo Analysis
```bash
clj-kondo --lint src test --config '{:output {:format :edn}}' > /tmp/kondo-results.edn
```

### Reflection Warnings
```bash
# Look for reflection warnings in compilation
clojure -M:dev -e "(set! *warn-on-reflection* true)" 2>&1 | grep "reflection warning"
```

### Unused Bindings
```bash
# clj-kondo reports these automatically
clj-kondo --lint src --config '{:linters {:unused-binding {:level :warning}}}'
```

### Complex Functions
- Functions > 30 lines
- Functions with > 4 parameters
- Deeply nested conditionals (> 3 levels)

### Tests Bypassing Public API
Tests should exercise the same code paths as production. Flag:
- Test helpers that call private functions (`#'ns/private-fn` or `defn-` accessed via var)
- Test helpers using a different execution engine than production (e.g., `query-task` in tests vs `collect-emissions` in production)
- Tests that mock internals instead of testing through the public API
- Test fixtures that duplicate production logic instead of calling it

```clojure
;; WRONG - test helper uses different execution path than production
(defn run-compiled [env entity query]
  (ceql/query-task env entity query))  ;; production uses pipeline/run

;; CORRECT - test helper calls production code
(defn run-compiled [tree registry entity query]
  (pipeline/run {:tree tree :registry registry :entity entity :output-keys query}))
```

### Unapproved requiring-resolve
`requiring-resolve` defers namespace loading to runtime, hiding dependencies and making code harder to reason about. Every use must be explicitly approved by the user with a justifying comment.

```bash
# Find all requiring-resolve usages
grep -rn 'requiring-resolve' src/ test/
```

Flag any occurrence that does not have an adjacent comment explaining why lazy loading is necessary. Legitimate uses include breaking circular dependencies and optional feature loading.

```clojure
;; WRONG - no justification
(let [f (requiring-resolve 'some.ns/fn)]
  (f args))

;; CORRECT - justified and approved
;; requiring-resolve: breaks circular dep between pipeline and checkpoint
(let [f (requiring-resolve 'wemble.checkpoint/load-checkpoint)]
  (f dir key))
```

### Duplication Detection
- Similar function bodies across files
- Repeated inline patterns
- Copy-pasted test fixtures

### Integrant Lifecycle
```clojure
;; WRONG - Missing halt! implementation
(defmethod ig/init-key :my/service [_ config]
  (start-something config))

;; CORRECT - Proper lifecycle
(defmethod ig/init-key :my/service [_ config]
  (start-something config))

(defmethod ig/halt-key! :my/service [_ service]
  (stop-something service))
```

## Project-Specific Extensions

Projects can extend the analysis by adding project-specific patterns. For example, if your project uses a state management library or event system, add patterns to check for common violations of those patterns.

## Related Skills

- `clojure-coding-standards` - Code quality standards
- `integrant-lifecycle` - Service lifecycle patterns
- `error-handling-patterns` - Error handling best practices
