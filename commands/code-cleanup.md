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
    ├── Agent 5: Code Duplication (structural comparison)
    └── Agent 6: Dependency Topology (namespace coupling)
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

2. **Missing bang suffix:** Search for functions that call swap!/reset!/send/vreset!/vswap!
   but whose defn name doesn't end with !. **Flag public functions as HIGH priority** —
   callers assume no-bang functions are pure. Flag private functions as MEDIUM.
   This includes functions that mutate atoms received as parameters or created internally.

3. **Unapproved requiring-resolve:** Search for requiring-resolve in source files
   (not test/). Flag any without a justifying comment. Example:


   ;; WRONG - no justification
   (let [f (requiring-resolve 'some.ns/fn)] (f args))

   ;; CORRECT - justified and approved
   ;; requiring-resolve: breaks circular dep between pipeline and checkpoint
   (let [f (requiring-resolve 'wemble.checkpoint/load-checkpoint)] (f dir key))

4. **Scattered defaults:** Search for (or (:key ...) default-value) patterns in
   function bodies. To distinguish edge vs inner functions: edge functions are
   typically public, named with prefixes like create-, init-, handle-, -handler,
   or are the first function in a call chain (called from routes/main). Inner
   functions are private (defn-) or called only by other functions in the same
   namespace. Only flag defaults in clearly inner functions — when uncertain, skip.

5. **Hidden global state:** Search for @global-, @app-, deref of module-level vars
   inside function bodies (not at top level).

6. **Collection anti-patterns:** Transducers are the preferred collection processing
   approach — they compose without intermediate sequences and work with any reducible
   source. Search for patterns that should use transducers instead:

   - (doall (map ...))  or  (doall (filter ...))  → (into [] (map f) coll)
   - (vec (map ...))  → (into [] (map f) coll)
   - (->> coll (map ...) (filter ...))  → (into [] (comp (map f) (filter p)) coll)
   - (for [x coll ...] ...)  → (into [] (comp (mapcat ...) (map ...)) coll)
   - Nested (map f (filter p coll))  → (sequence (comp (filter p) (map f)) coll)
   - (reduce f init (map g coll))  → (transduce (map g) f init coll)

   Exceptions (do NOT flag):
   - (map f coll) returned lazily to a caller expecting a seq (no realization)
   - Single (map f coll) with no wrapping vec/doall/into (idiomatic for lazy pipelines)
   - (for ...) in test data construction (readability over performance)

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
- Configuration divergence between test and production defaults
- Manual construction of internal data structures
- Test helper passthrough gaps (helpers that don't forward options to underlying API)

**Instructions for agent:**

```
Analyze test files in test/ for quality violations that cause tests to exercise
different code paths than production. This is the most important test quality
check — tests that pass but don't validate production behavior are worse than
no tests at all.

1. **Private var access:** Search for #' (var quote) in test files. Each occurrence
   is a test reaching into implementation details. Flag with the var being accessed.
   Severity: HIGH — these tests bypass public API guards and test paths users never
   exercise. If the internal changes but the public behavior stays the same, the
   test breaks spuriously. Conversely, if the public behavior breaks but internals
   still pass, the test misses the bug.

2. **Configuration divergence:** Identify default configurations in production code
   (look for `:or` defaults in destructuring, default plugin lists, default option
   maps). Then search test code for places that override these defaults. Flag tests
   that use different configurations than production defaults, unless the test is
   explicitly testing the override behavior.

   Examples of what to detect:
   - Production defaults to plugins [A B] but test uses only [A]
   - Production uses a specific merge strategy but test constructs data directly
   - Test helper builds env/config differently than the public API would

   How to find production defaults:
   - Search for :or clauses in public function destructuring
   - Search for defn argument defaults
   - Look at factory functions that build standard configurations

   Severity: MEDIUM when test accidentally omits production defaults.
   Severity: LOW when test intentionally tests a specific configuration.

3. **Manual construction of internal data structures:** Search test code for
   hand-built maps that match internal data shapes produced by production code.
   These become stale when internals change.

   Examples of what to detect:
   - Tests constructing error maps (e.g., {::error {:message "..."}}) instead of
     letting the error-handling infrastructure produce them
   - Tests building metadata maps that match internal emission/state shapes
   - Tests constructing resolver configs or execution plans by hand

   How to detect:
   - Search for namespace-qualified keywords from the production namespace used
     in test map literals (not in assertions, but as test input data)
   - Compare test helper data shapes against what production functions return

   Severity: MEDIUM — fragile coupling to internals.

4. **Test helper passthrough gaps:** For each test helper function (defn/defn- in
   test files), check whether it forwards all relevant options to the underlying
   production API it wraps.

   How to detect:
   - Find test helpers that call production API functions
   - Compare the helper's parameter set against the production function's options
   - Flag helpers that destructure/extract some options but don't pass through
     the rest (e.g., extracts :entity and :n but ignores :plugins)

   Example:
   ;; WRONG — helper extracts some opts but doesn't forward :plugins
   (defn test-signal [resolvers query opts assertion-fn]
     (let [env (pci/register resolvers)
           n (:n opts 1)
           flow (reactive-signal-eql env query)]  ;; opts NOT passed!
       ...))

   ;; CORRECT — forwards relevant opts
   (defn test-signal [resolvers query opts assertion-fn]
     (let [env (pci/register resolvers)
           n (:n opts 1)
           flow (reactive-signal-eql env query (select-keys opts [:plugins]))]
       ...))

   Severity: HIGH — silently tests different behavior than production.

5. **Excessive mocking:** Search for with-redefs, with-bindings, and mock/stub
   patterns. These often indicate tests coupled to implementation rather than behavior.

   Severity: MEDIUM for with-redefs on internal functions.
   Severity: LOW for with-redefs on external dependencies (acceptable).

6. **Duplicated production logic:** Look for test helper functions that reimplement
   logic that already exists in production code (e.g., manually building data
   structures that a production function already creates).

   Severity: MEDIUM — maintenance burden and divergence risk.

Return findings as a list of {file, line, pattern, violation, severity}.
Do NOT create GitHub issues — just return findings.
```

### Agent 6: Dependency Topology

**Concern:** Namespace coupling and dependency health.
**Detection method:** clj-kondo analysis + REPL namespace introspection.

**Detects:**
- Circular namespace dependencies
- High fan-in namespaces (imported by 10+ others — high blast radius on change)
- Orphan namespaces (not required by any other namespace)
- High fan-out namespaces (require 10+ others — tightly coupled)

**Instructions for agent:**

```
Analyze namespace dependency structure across src/ and test/.

1. **Circular dependencies:** Run clj-kondo with circular-dependency linter enabled:
   clj-kondo --lint src --config '{:linters {:namespace {:level :warning}}}'
   Or at the REPL, check ns-aliases for bidirectional requires.
   Flag each circular pair with both namespace names.

2. **High fan-in (blast radius):** Count how many namespaces require each namespace.
   Flag any namespace required by 10+ others. These are high-impact change targets
   that need strong test coverage and stable APIs.

3. **Orphan namespaces:** Find namespaces not required by any other namespace in
   the project. Exclude entry points (main, init, test namespaces). Orphans are
   candidates for deletion or indicate missing requires.

4. **High fan-out (coupling):** Count how many namespaces each namespace requires.
   Flag any namespace requiring 10+ others. These are tightly coupled and may need
   splitting or interface extraction.

Return findings as a list of {namespace, issue-type, detail, severity}.
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
   - "Dependency topology" (if any)
5. **Skip empty categories** — don't create issues for categories with zero findings
6. **Flag recurring patterns** — if any single violation type appears in 3+ files,
   append to the GitHub issue:

   > **Recurring pattern detected:** [violation] appears in N files. Consider running
   > `/five-whys` to determine if a skill or CLAUDE.md update would prevent this.
   > Relevant skill: [skill-name].

   Violation → skill mapping:
   - Scattered defaults → `clojure-coding-standards` (FUNCTIONAL-PRINCIPLES.md)
   - Collection anti-patterns → `clojure-coding-standards` (COLLECTION-PATTERNS.md)
   - Unapproved mutations → `clojure-coding-standards` (SKILL.md)
   - Function size → `clojure-coding-standards` (CODE-ORGANIZATION.md)
   - Tests bypassing API → `bdd-scenarios` or project CLAUDE.md
   - Config divergence / passthrough gaps → `testing-patterns` or project CLAUDE.md
   - Manual internal construction → `testing-patterns` or project CLAUDE.md

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
| **High** | Reflection warnings, unapproved mutations, tests bypassing public API via `#'`, test helper passthrough gaps, arity mismatches |
| **Medium** | Unused bindings, function size >80 LOC, scattered defaults, collection anti-patterns, config divergence (accidental), manual internal data construction, excessive mocking |
| **Low** | Namespace size warnings, nesting depth, missing bang suffix, config divergence (intentional) |

## Extending

To add a new analysis concern, add a new agent section above. Each agent must:
1. Have a single, named concern
2. Use one primary detection method
3. Return findings as structured data (not prose)
4. Never create GitHub issues directly

## Auto-Fix Scripts

Agents can optionally produce bb + rewrite-clj scripts that fix violations, not just report them. See [rewrite-clj-transforms](../skills/rewrite-clj-transforms/) for the recipe library.

When an agent produces a fix script, the orchestrator includes it in the GitHub issue for user approval before running. Fix scripts should be self-contained bb scripts that can be run with `bb fix-script.clj`.

## Related Skills

- `clojure-coding-standards` — The standards these agents enforce
- `rewrite-clj-transforms` — Structural code modification for auto-fix scripts
- `error-handling-patterns` — Error handling best practices
- `integrant-lifecycle` — Service lifecycle patterns
