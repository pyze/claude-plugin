# /code-cleanup

Analyze code for violations of Clojure best practices. Dispatches focused agents in parallel, each examining a cohesive subset of standards, then creates categorized GitHub issues from their findings.

## Architecture

```
/code-cleanup (orchestrator)
    │
    ├── Agent 1: Static Analysis (clj-kondo)
    ├── Agent 2: Code Organization (structural)
    ├── Agent 3: Purity & Standards (functional principles)
    ├── Agent 4: Test Quality (test-specific)
    └── Agent 5: Code Duplication (structural comparison)
    │
    ▼
Collect findings → Create GitHub issues by category
```

Each agent is decomplected: one detection method, one concern, no shared state. The orchestrator is thin — dispatch, collect, report.

## Usage

```bash
/code-cleanup           # Analyze full project
/code-cleanup src/viz/  # Analyze specific directory
```

## Agent Specifications

### Agent 1: Static Analysis

**Concern:** Machine-detectable issues via clj-kondo.
**Detection method:** Run clj-kondo, parse structured output.

**Detects:**
- Unused bindings and imports
- Reflection warnings
- Unresolved symbols
- Arity mismatches
- Redundant expressions

**Instructions for agent:**

```
Run clj-kondo static analysis on the project:

  clj-kondo --lint src test --config '{:output {:format :edn}}' > /tmp/kondo-results.edn

Parse the EDN output. Categorize findings by severity:

**High priority:**
- Reflection warnings (performance impact)
- Unresolved symbols (potential runtime errors)
- Arity mismatches (will crash at runtime)

**Medium priority:**
- Unused bindings (code clarity)
- Unused imports (namespace hygiene)
- Redundant expressions

Return findings as a list of {file, line, category, severity, message}.
Do NOT create GitHub issues — just return findings.
```

### Agent 2: Code Organization

**Concern:** Structural complexity — function/namespace size, nesting depth.
**Detection method:** Read files and count s-expression spans (grep/wc cannot reliably measure Clojure function boundaries).

**Detects:**
- Functions exceeding 80 LOC (review needed) or 150 LOC (red flag)
- Namespaces exceeding 1500 LOC
- Functions with 5+ parameters
- Nesting depth > 3 let-binding levels
- Refactoring triggers: 2+ independent loops, variable reassignment

**Instructions for agent:**

```
Analyze code organization across src/ and test/ directories.

For each .clj, .cljs, and .cljc file:

1. **Namespace size:** Count total LOC. Flag >1000 as review, >1500 as red flag.

2. **Function size:** For each defn/defn-/defmethod, count LOC from opening paren
   to closing paren. Flag >80 as review, >150 as red flag.

3. **High-arity functions:** Find functions with 5+ parameters (excluding map
   destructuring, which is the fix). Flag with the function name and arity.

4. **Nesting depth:** Find let-bindings nested 3+ levels deep. Report file, line,
   and function name.

For function size, read files and count lines between defn/defmethod opening and
closing parens. grep/wc cannot reliably measure Clojure function boundaries due
to s-expression nesting. Focus on the largest files first (use wc -l to prioritize).

Return findings as a list of {file, function-name, metric, value, threshold, severity}.
Do NOT create GitHub issues — just return findings.
```

### Agent 3: Purity & Standards Compliance

**Concern:** Functional programming principle violations.
**Detection method:** Pattern grep for known anti-patterns.

**Detects:**
- Unapproved mutable state (`atom`, `volatile!`, `ref`, `agent` without approval comment)
- Unapproved `requiring-resolve` usage
- Scattered defaults (`(or (:key x) default)` in non-edge functions)
- Hidden dependencies on global state (`@global-*`, `deref` in non-edge functions)
- Missing `!` suffix on functions with side effects
- `doall` or `vec` on lazy sequences (should use `into`)
- Threading macros on collections (`->>` with `map`/`filter`)
- `for` macro usage (should use transducers or `xf/for`)

**Instructions for agent:**

```
Search for functional programming violations across src/ and test/ directories.

For each pattern, grep and then verify context (some patterns have legitimate uses):

1. **Unapproved mutations:** Search for atom/volatile!/ref/agent. Check if adjacent
   lines contain "MUTATION APPROVED" or "APPROVED" comment. Flag those without.

2. **Unapproved requiring-resolve:** Search for requiring-resolve in source files
   (not test/). Flag any without a justifying comment. Example:

   ;; WRONG - no justification
   (let [f (requiring-resolve 'some.ns/fn)] (f args))

   ;; CORRECT - justified and approved
   ;; requiring-resolve: breaks circular dep between pipeline and checkpoint
   (let [f (requiring-resolve 'wemble.checkpoint/load-checkpoint)] (f dir key))

3. **Scattered defaults:** Search for (or (:key ...) default-value) patterns in
   function bodies. To distinguish edge vs inner functions: edge functions are
   typically public, named with prefixes like create-, init-, handle-, -handler,
   or are the first function in a call chain (called from routes/main). Inner
   functions are private (defn-) or called only by other functions in the same
   namespace. Only flag defaults in clearly inner functions — when uncertain, skip.

4. **Hidden global state:** Search for @global-, @app-, deref of module-level vars
   inside function bodies (not at top level).

5. **Collection anti-patterns:** Search for:
   - (doall (map ...))  or  (doall (filter ...))
   - (vec (map ...))
   - (->> coll (map ...) (filter ...))
   - (for [x coll ...] ...)

6. **Missing bang suffix:** Search for functions that call swap!/reset!/send/jdbc
   but whose defn name doesn't end with !.

7. **Integrant lifecycle:** Search for ig/init-key defmethods. For each, verify a
   matching ig/halt-key! exists. Missing halt-key! means resources leak on system
   restart. Example:

   ;; WRONG - Missing halt! implementation
   (defmethod ig/init-key :my/service [_ config]
     (start-something config))

   ;; CORRECT - Proper lifecycle
   (defmethod ig/init-key :my/service [_ config]
     (start-something config))
   (defmethod ig/halt-key! :my/service [_ service]
     (stop-something service))

Return findings as a list of {file, line, pattern, violation, severity}.
Do NOT create GitHub issues — just return findings.
```

### Agent 5: Code Duplication

**Concern:** Repeated patterns that could be extracted into shared functions.
**Detection method:** Structural comparison of function bodies.

**Detects:**
- Similar function bodies across files (>10 LOC of near-identical logic)
- Repeated inline patterns (same 3+ line sequence appearing 3+ times)
- Copy-pasted test fixtures

**Instructions for agent:**

```
Search for code duplication across src/ and test/ directories.

1. **Similar function bodies:** Look for functions in different namespaces with
   near-identical implementations. Focus on functions >10 LOC.

2. **Repeated inline patterns:** Search for identical or near-identical code
   sequences (3+ lines) appearing in 3+ locations.

3. **Copy-pasted test fixtures:** Look for test setup/teardown code that is
   duplicated across test namespaces instead of extracted into a shared helper.

Return findings as a list of {files, lines, pattern, severity}.
Do NOT create GitHub issues — just return findings.
```

### Agent 4: Test Quality

**Concern:** Tests that don't exercise production code paths.
**Detection method:** Semantic code reading of test files.

**Detects:**
- Tests accessing private vars (`#'ns/private-fn`)
- Test helpers using different execution paths than production
- Tests that mock internals instead of using the public API
- Redundant test fixtures that duplicate production logic

**Instructions for agent:**

```
Analyze test files in test/ for quality violations.

1. **Private var access:** Search for #' (var quote) in test files. Each occurrence
   is a test reaching into implementation details. Flag with the var being accessed.

2. **Execution path divergence:** Look for test helper functions that call different
   functions than production code for the same operation. Example:

   ;; WRONG - test helper uses different execution path than production
   (defn run-compiled [env entity query]
     (ceql/query-task env entity query))  ;; production uses pipeline/run

   ;; CORRECT - test helper calls production code
   (defn run-compiled [tree registry entity query]
     (pipeline/run {:tree tree :registry registry :entity entity :output-keys query}))

   Compare test helpers against the public API of the module under test.

3. **Excessive mocking:** Search for with-redefs, with-bindings, and mock/stub
   patterns. These often indicate tests coupled to implementation rather than behavior.

4. **Duplicated production logic:** Look for test helper functions that reimplement
   logic that already exists in production code (e.g., manually building data
   structures that a production function already creates).

Return findings as a list of {file, line, pattern, violation, severity}.
Do NOT create GitHub issues — just return findings.
```

## Orchestrator Behavior

After all agents complete:

1. **Merge findings** from all agents into a single collection
2. **Deduplicate** — same file+line from multiple agents = single finding
3. **Group by severity** (high → medium → low)
4. **Create one GitHub issue per category** with a task-list checklist:
   - "Static analysis findings" (if any)
   - "Code organization violations" (if any)
   - "Functional purity violations" (if any)
   - "Test quality issues" (if any)
   - "Code duplication" (if any)
5. **Skip empty categories** — don't create issues for categories with zero findings

Issue format:
```markdown
## [Category] Code Cleanup Findings

**Severity:** [High/Medium/Low counts]

### High Priority
- [ ] `file.clj:42` — Description of finding

### Medium Priority
- [ ] `file.clj:88` — Description of finding
```

## Priority Levels

| Severity | Categories |
|----------|-----------|
| **High** | Reflection warnings, unapproved mutations, tests bypassing public API, arity mismatches |
| **Medium** | Unused bindings, function size >80 LOC, scattered defaults, collection anti-patterns |
| **Low** | Namespace size warnings, nesting depth, missing bang suffix |

## Extending

To add a new analysis concern, add a new agent section above. Each agent must:
1. Have a single, named concern
2. Use one primary detection method
3. Return findings as structured data (not prose)
4. Never create GitHub issues directly

## Related Skills

- `clojure-coding-standards` — The standards these agents enforce
- `error-handling-patterns` — Error handling best practices
- `integrant-lifecycle` — Service lifecycle patterns
