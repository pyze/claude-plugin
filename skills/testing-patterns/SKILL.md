---
name: testing-patterns
description: "Test quality patterns that ensure tests exercise production code paths. Use when writing tests, reviewing test code, debugging test/production divergence, or auditing test helpers for correctness gaps."
---

# Testing Patterns

Tests that pass but don't validate production behavior are worse than no tests at all. This skill identifies patterns where tests silently exercise different code paths than production.

## When to Use This Skill

**Use THIS skill if:**
- Writing or reviewing test code
- Debugging why a test passes but production fails
- Auditing test helpers for correctness gaps
- Deciding how to structure test fixtures

**Use DIFFERENT skill if:**
- TDD workflow mechanics -> [repl-driven-development](../repl-driven-development/)
- Converting specs to BDD scenarios -> [bdd-scenarios](../bdd-scenarios/)
- Mocking decisions -> [clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md](../clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md) (with-redefs section)

---

## Core Principle

**Tests must exercise the same code paths as production.** Every divergence between test and production is a gap where bugs hide.

---

## Anti-Pattern 1: Private Var Access

Tests reaching into implementation details with `#'` (var quote) bypass public API guards and test paths users never exercise.

```clojure
;; WRONG - Accessing private var directly
(deftest test-internal-parse
  (is (= {:parsed true} (#'my.ns/parse-internal "input"))))

;; CORRECT - Test through the public API
(deftest test-parse
  (is (= {:parsed true} (my.ns/parse "input"))))
```

**Why this matters:** If the internal changes but public behavior stays the same, the test breaks spuriously. If public behavior breaks but internals still pass, the test misses the bug.

**Detection:** Search for `#'` (var quote) in test files. Each occurrence is a test reaching into implementation details.

**Severity:** HIGH

---

## Anti-Pattern 2: Configuration Divergence

Tests using different default configurations than production silently test different behavior.

```clojure
;; Production code with defaults
(defn create-pipeline
  [{:keys [plugins strategy]
    :or {plugins [:validation :enrichment]
         strategy :merge-all}}]
  ...)

;; WRONG - Test omits production defaults
(deftest test-pipeline
  (let [p (create-pipeline {:plugins [:validation]})]  ;; Missing :enrichment!
    (is (valid? p))))

;; CORRECT - Test uses production defaults (or tests override explicitly)
(deftest test-pipeline-defaults
  (let [p (create-pipeline {})]  ;; Gets all production defaults
    (is (valid? p))))

(deftest test-pipeline-custom-plugins
  ;; Explicitly testing override behavior - this is intentional
  (let [p (create-pipeline {:plugins [:validation]})]
    (is (valid? p))))
```

**Detection:**
- Find `:or` defaults in public function destructuring
- Find factory functions that build standard configurations
- Compare test invocations against these defaults
- Flag tests that accidentally omit production defaults

**Severity:** MEDIUM when test accidentally omits defaults. LOW when intentionally testing specific configuration.

---

## Anti-Pattern 3: Manual Internal Data Construction

Tests that hand-build maps matching internal data shapes become stale when internals change.

```clojure
;; WRONG - Hand-building internal error shape
(deftest test-error-handling
  (let [error {::pipeline/error {:message "fail" :code :timeout}}]
    (is (retryable? error))))

;; CORRECT - Let production code produce the shape
(deftest test-error-handling
  (let [error (pipeline/make-error :timeout "fail")]
    (is (retryable? error))))
```

**Detection:**
- Search for namespace-qualified keywords from production namespaces used in test map literals (as test input, not in assertions)
- Compare test helper data shapes against what production functions return

**Severity:** MEDIUM — fragile coupling to internals.

---

## Anti-Pattern 4: Test Helper Passthrough Gaps

Test helpers that wrap production APIs but don't forward all relevant options silently test different behavior.

```clojure
;; WRONG - Helper extracts some opts but doesn't forward :plugins
(defn test-signal [resolvers query opts assertion-fn]
  (let [env (pci/register resolvers)
        n (:n opts 1)
        flow (reactive-signal-eql env query)]  ;; opts NOT passed!
    ...))

;; CORRECT - Forwards relevant opts
(defn test-signal [resolvers query opts assertion-fn]
  (let [env (pci/register resolvers)
        n (:n opts 1)
        flow (reactive-signal-eql env query (select-keys opts [:plugins]))]
    ...))
```

**Detection:**
- Find test helpers that call production API functions
- Compare the helper's parameter set against the production function's options
- Flag helpers that destructure/extract some options but don't pass through the rest

**Severity:** HIGH — silently tests different behavior than production.

---

## Anti-Pattern 5: Excessive Mocking

`with-redefs` on internal functions creates tests coupled to implementation rather than behavior. See also [FUNCTIONAL-PRINCIPLES.md](../clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md) for the deeper principle: if you need `with-redefs`, the production code has a hidden dependency that should be an explicit parameter.

```clojure
;; WRONG - Mocking internal function
(deftest test-process
  (with-redefs [my.ns/internal-helper (fn [_] :mock)]
    (is (= :expected (my.ns/process input)))))

;; CORRECT - Make dependency explicit
(deftest test-process
  (is (= :expected (my.ns/process input {:helper mock-helper}))))
```

**Detection:** Search for `with-redefs`, `with-bindings`, and mock/stub patterns in test files.

**Severity:** MEDIUM for `with-redefs` on internal functions. LOW for `with-redefs` on external dependencies (acceptable as temporary workaround).

---

## Anti-Pattern 6: Duplicated Production Logic

Test helpers that reimplement logic already in production code diverge over time.

```clojure
;; WRONG - Test helper reimplements production normalization
(defn test-normalize [entity]
  (assoc entity :id (str (:type entity) "-" (:name entity))))

;; CORRECT - Use the production function
(defn test-normalize [entity]
  (production.ns/normalize entity))
```

**Detection:** Look for test helper functions whose body closely matches a production function.

**Severity:** MEDIUM — maintenance burden and divergence risk.

---

## Summary

| Anti-Pattern | Severity | Key Signal |
|-------------|----------|------------|
| Private var access (`#'`) | HIGH | Test bypasses public API |
| Test helper passthrough gaps | HIGH | Helper doesn't forward options |
| Configuration divergence | MEDIUM | Test uses different defaults |
| Manual internal construction | MEDIUM | Hand-built maps matching internal shapes |
| Excessive mocking (`with-redefs`) | MEDIUM | Test coupled to implementation |
| Duplicated production logic | MEDIUM | Test reimplements production code |

**The test**: For every test, ask: "Would this test still pass if I changed the internals but kept the public behavior identical?" If the answer is no, the test is coupled to implementation.
