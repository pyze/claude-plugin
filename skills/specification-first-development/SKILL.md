---
name: specification-first-development
description: Write specifications before code to clarify requirements. Use when starting features with unclear requirements or complex business logic.
---

# Specification-First Development Skill

Specifications are the source of truth that drives implementation, not vice versa.

## Core Principle

**Code serves specifications.** Write specifications before code to preserve clear intent from requirements to implementation.

---

## Skill Boundary

This skill covers: **When/what to specify** - deciding if specs are needed, how to write them.

**Use DIFFERENT skill if:**
- Where to store documentation → [documentation-maintenance](../documentation-maintenance/)
- Recording discoveries → [learning-capture](../learning-capture/)
- Converting spec examples to tests → [bdd-scenarios](../bdd-scenarios/)

## When to Use This Skill

**Consider using `superpowers:brainstorming` first** if you haven't explored WHAT to build yet.

**Use THIS skill if**:
- ✅ Task complexity > 2 hours estimated
- ✅ Requirements are ambiguous or incomplete
- ✅ Multiple valid implementation approaches exist
- ✅ Integration with 2+ existing systems
- ✅ Multiple people need to understand the requirements
- ✅ You want to prevent implementing the wrong thing

**Skip this skill if**:
- Task is simple/well-defined (< 30 minutes)
- Pattern already exists in codebase to follow
- Pure exploration/research phase
- You're fixing a clear bug (behavior already specified)
- Well-known patterns (CRUD, standard workflows)
- One-off scripts or throwaway code

### Time Threshold Guidelines

```
Feature Complexity       | Specification Level
─────────────────────────┼─────────────────────────
< 30 minutes            | Skip spec (just implement)
30 min - 2 hours        | Use judgment based on:
                        | - Is there any ambiguity?
                        | - Will others read this code?
                        | - Are edge cases unclear?
> 2 hours               | Always use spec-first
```

**30 min - 2 hour range**: Use spec-first if ANY of these apply:
- 2+ distinct implementations exist (need to pick one)
- Edge cases not documented in existing code
- Integrates with 2+ systems
- User-facing behavior that needs validation

**Trade-off**: Specifications take 20-40% of feature time. Use when value exceeds cost.

### Worked Examples

| Feature | Est. Time | Decision | Why |
|---------|-----------|----------|-----|
| Add "back" button | 15 min | Skip spec | Simple, clear, no ambiguity |
| Refactor entity schema | 1 hour | Use spec | Multiple approaches, affects other code |
| Fix login redirect bug | 30 min | Skip spec | Behavior already defined (bug) |
| Add password reset flow | 3 hours | Use spec | Complex, user-facing, security implications |
| Add sort to table component | 45 min | Judgment call | Clear if "just add UI sorting", spec if "needs server sort + persistence" |

---

## Specification Structure

**Every specification should include:**

```clojure
{:specification/id            "feature-name-001"  ; Unique identifier
 :specification/intent        "Clear description of what and why"
 :specification/inputs        [{:name "param" :type :keyword :required true}]
 :specification/outputs       {:success {...} :error {...}}
 :specification/examples      [{:input {...} :output {...}}]
 :specification/uncertainties ["[?] Open questions or assumptions"]}
```

### Example

```clojure
{:specification/id       "user-auth-001"
 :specification/intent   "Authenticate user with email and password"
 :specification/inputs   [{:name "email" :type :string :required true}
                          {:name "password" :type :string :required true}]
 :specification/outputs  {:success {:user-id :uuid :auth-token :string}
                          :error   {:type :keyword :message :string}}
 :specification/examples [{:input  {:email "user@example.com" :password "secret"}
                           :output {:user-id #uuid "..." :auth-token "..."}}]
 :specification/uncertainties ["[?] Token expiration: 24 hours or 7 days?"]}
```

---

## Natural Language First

**Express requirements in plain language before translating to code:**

```markdown
## Specification: Load Data from API

**Intent**: Fetch user data from external API and store in local state.

**Inputs**:
- user-id (uuid, required): The user to fetch
- include-profile (boolean, optional): Whether to include profile data

**Process**:
1. Call external API with user-id
2. Parse response into application data model
3. Store in application state

**Outputs**:
- Success: {:user {...} :profile {...}}
- Error: {:type :api-error | :parse-error, :message string}

**Open Questions**:
- [?] Retry policy on API failures?
- [?] Cache duration for fetched data?
```

---

## Resolving Ambiguities

**CRITICAL: Ask ONE question at a time when clarifying.**

```
WRONG - Multiple questions at once:
"Should we cache? What TTL? Redis or in-memory?
What eviction policy? Max size?"

RIGHT - One focused question:
"Should we implement caching for this feature?"
[Wait for answer]
"What caching backend do you prefer: Redis or in-memory?"
[Wait for answer]
"What's an appropriate TTL for cached entries?"
[Continue one at a time]
```

### When to Stop and Ask

```
Writing specification and encounter:
    │
    ├─ Ambiguous requirement? → Ask for clarification
    ├─ Conflicting requirements? → Ask which takes priority
    ├─ Missing information? → Ask for specifics
    ├─ Multiple valid approaches? → Ask for preference
    └─ Assumption needed? → Ask to validate assumption

DO NOT proceed with coding until ambiguities are resolved!
```

**Document the clarification:**

```clojure
;; BEFORE clarification
{:specification/uncertainties ["[?] Maximum file size: 100MB or 1GB?"]}

;; AFTER asking user
{:specification/constraints ["Maximum file size: 1GB"]
 :specification/rationale   "User confirmed 1GB limit sufficient"}
```

---

## 4-Phase Workflow

### Phase 1: Specify
1. Write natural language specification
2. Identify inputs, outputs, edge cases
3. Document uncertainties
4. **Ask user to clarify ONE question at a time**
5. Create concrete examples

### Phase 2: Research
6. Validate assumptions at REPL
7. Discover technical constraints
8. **If constraints conflict with spec, ask user for priority**
9. Refine specification based on findings

### Phase 3: Implement
10. Code implements specification contract
11. Link code to specification ID in docstrings
12. **If implementation reveals ambiguity, STOP and ask**
13. Update specification if needed

### Phase 4: Verify
14. Test against specification examples — see [bdd-scenarios](../bdd-scenarios/) for converting spec examples into Given/When/Then scenarios
15. Ensure outputs match specification
16. Verify error handling covers spec error cases

---

## Traceability

**Link every function to its specification:**

```clojure
(defn authenticate-user
  "Authenticate user with email and password.

  Implements specification: user-auth-001

  Args:
    credentials - Map with :email and :password

  Returns:
    {:user-id uuid, :auth-token string} on success
    {:type keyword, :message string} on error"
  [{:keys [email password]}]
  ...)
```

---

## Living Documents

**Bidirectional updates - specs and code stay synchronized:**

```
Requirements change?
    │
    ├─ Update specification FIRST
    ├─ Review changes (one question at a time)
    └─ Then update code to match

Implementation reveals issues?
    │
    ├─ Document in specification/uncertainties
    ├─ Ask user to clarify conflicts
    ├─ Refine specification
    └─ Update code to match refined spec
```

---

## Specification-Driven Testing

**Specification examples become tests:**

```clojure
;; Specification example becomes test
(deftest authenticate-user-test
  (testing "Specification example: user-auth-001"
    (let [result (authenticate-user {:email "user@example.com"
                                     :password "secret"})]
      (is (uuid? (:user-id result)))
      (is (string? (:auth-token result))))))
```

### Specification Validation with Truss

Use Truss assertions to enforce specification contracts at runtime:

```clojure
;; Specification defines inputs
{:specification/inputs [{:name "email" :type :string :required true}]}

;; Implementation validates against spec
(defn authenticate-user
  "Implements specification: user-auth-001"
  [{:keys [email password]}]
  (have! [:and string? (complement str/blank?)] email
         :data {:type :spec/invalid-email :spec-id "user-auth-001"})
  ;; Implementation...
  )
```

See [error-handling-patterns skill](../error-handling-patterns/) for complete Truss assertion patterns.

---

## Anti-Patterns

- **Don't**: Write vague specs ("handle errors appropriately")
- **Don't**: Skip spec for "obvious" features (>30 min = needs spec)
- **Don't**: Implement before resolving spec ambiguities
- **Don't**: Write spec after implementation (defeats purpose)

---

## Summary

1. **Specifications before code** - Define intent first
2. **Natural language first** - Plain language before Clojure
3. **Ask ONE question at a time** - Resolve ambiguities clearly
4. **Don't assume** - Validate uncertainties with user
5. **4-phase workflow** - Specify → Research → Implement → Verify
6. **Traceability** - Link functions to specification IDs
7. **Living documents** - Specification ↔ Code stay synchronized
8. **Examples as tests** - Spec examples become executable tests
