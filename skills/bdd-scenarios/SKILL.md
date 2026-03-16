---
name: bdd-scenarios
description: Convert specification examples into executable Given/When/Then scenarios using clojure.test. Use when bridging specs to tests, writing behavior-driven scenarios, or deciding between BDD scenarios vs unit tests.
---

# BDD Scenarios Skill

Bridge between specifications and executable tests using Given/When/Then structure.

## Skill Boundary

This skill covers: **Converting specification examples into executable behavioral scenarios.**

**Use DIFFERENT skill if:**
- TDD red-green-refactor workflow → `superpowers:test-driven-development`
- Writing specifications → [specification-first-development](../specification-first-development/)

## When to Use This Skill

**Use THIS skill if:**
- You have a specification with examples/acceptance criteria to convert into tests
- You need to verify behavior (not implementation details)
- You want Given/When/Then structure for clarity
- Specification uncertainties suggest edge case scenarios

**Skip this skill if:**
- Writing pure unit tests for internal functions
- Testing implementation details (data structures, algorithms)
- E2E browser testing (use project-specific testing patterns)

---

## Core Pattern: Given/When/Then in clojure.test

BDD scenarios use `testing` blocks with descriptive Given/When/Then labels:

```clojure
(deftest user-authentication-test
  (testing "Given valid credentials, When authenticating, Then returns auth token"
    (let [credentials {:email "user@example.com" :password "secret"}
          result (authenticate-user credentials)]
      (is (uuid? (:user-id result)))
      (is (string? (:auth-token result)))))

  (testing "Given invalid password, When authenticating, Then returns error"
    (let [credentials {:email "user@example.com" :password "wrong"}
          result (authenticate-user credentials)]
      (is (= :invalid-credentials (:type result))))))
```

### Structure

```
Given [initial state/context]
When  [action/event occurs]
Then  [expected outcome]
```

Each `testing` block is one scenario. Group related scenarios in one `deftest`.

---

## Converting Specifications to Scenarios

### From Spec Examples

```clojure
;; Specification
{:specification/examples
 [{:input {:email "user@example.com" :password "secret"}
   :output {:user-id #uuid "..." :auth-token "..."}}
  {:input {:email "user@example.com" :password "wrong"}
   :output {:type :invalid-credentials :message "..."}}]}

;; Each example becomes a scenario
(deftest authenticate-user-scenarios
  (testing "Given valid credentials, When authenticating, Then succeeds"
    ...)
  (testing "Given wrong password, When authenticating, Then returns invalid-credentials"
    ...))
```

### From Spec Uncertainties

Specification uncertainties often reveal important edge case scenarios:

```clojure
;; Specification uncertainty
;; [?] Token expiration: 24 hours or 7 days?

;; Becomes scenario after resolution
(testing "Given expired token (>24h), When accessing resource, Then returns unauthorized"
  ...)
```

---

## Scenario vs Unit Test Decision

| Characteristic | BDD Scenario | Unit Test |
|---------------|-------------|-----------|
| Tests **behavior** | Yes | Sometimes |
| Tests **implementation** | No | Yes |
| Derived from **spec** | Yes | Not necessarily |
| Readable by **non-developers** | Yes | Not usually |
| Tests **edge cases** | From spec uncertainties | From code analysis |
| Tests **internal functions** | No | Yes |

**Use scenarios for**: Public API behavior, user-facing features, spec verification.
**Use unit tests for**: Internal functions, data transformations, algorithm correctness.

---

## Checklist

Before writing scenarios:

- [ ] Specification exists with examples
- [ ] Each example maps to one scenario
- [ ] Scenarios describe behavior, not implementation
- [ ] Edge cases from spec uncertainties are covered
- [ ] Given/When/Then structure is clear and descriptive

---

## Summary

1. **Specs drive scenarios** - Each spec example becomes a Given/When/Then scenario
2. **Behavior over implementation** - Test what, not how
3. **Uncertainties become edge cases** - Spec [?] items reveal scenario gaps
4. **clojure.test `testing` blocks** - Use descriptive Given/When/Then labels
5. **Complement unit tests** - Scenarios for behavior, unit tests for internals
