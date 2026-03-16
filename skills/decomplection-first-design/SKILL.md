---
name: decomplection-first-design
description: Apply simple-over-easy design philosophy. Use when making design decisions, evaluating trade-offs, or choosing between approaches.
---

# Decomplection-First Design Skill

**We value decomplected solutions that are simple and correct over all other considerations, including expediency.**

## When to Use This Skill

**Use THIS skill if:**
- ✅ Designing new features or components
- ✅ Refactoring existing entangled code
- ✅ Choosing between implementation approaches
- ✅ Reviewing code for hidden dependencies
- ✅ Deciding whether to abstract or inline

**Use DIFFERENT skill if:**
- Specific error handling patterns → [error-handling-patterns](../error-handling-patterns/)
- Code size/organization → [clojure-coding-standards/CODE-ORGANIZATION.md](../clojure-coding-standards/CODE-ORGANIZATION.md)
- Pure function conventions → [clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md](../clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md)

---

## Core Principle

**Simple always wins.**

- **Simple** = not entangled, separable, composable (opposite of complex)
- **Easy** = nearby, familiar, requires little effort
- **Our choice**: Simple but hard > Easy but entangled

```
              Easy    | Hard
    ───────────────────────────
    Simple  | BEST    | OK
    ───────────────────────────
    Complex | BAD     | WORST
```

---

## Decomplection Decision Tree

When choosing between approaches:

```
Does this entangle multiple concerns?
Can I separate them cleanly?
    │
    ├─ YES, can separate → DECOUPLE FIRST
    │
    └─ NO → Can I express this as pure function?
             │
             ├─ YES → Use pure function (simple!)
             │
             └─ NO → Can I push effects to boundary?
                      │
                      ├─ YES → Pure core + thin IO layer
                      │
                      └─ NO → Minimize entanglement
                               Document hidden deps
```

---

## Three Core Patterns

### Pattern 1: Extract Concerns

```clojure
;; ENTANGLED: One function doing multiple things
(defn load-query [s]
  (let [parsed (parse s)]
    (validate parsed)))

;; DECOMPLECTED: Separately testable, reusable
(comp validate parse)
```

### Pattern 2: Use Protocols

```clojure
;; ENTANGLED: Hard-coded implementation
(defn execute-query [q]
  (let [result (db/query q)]
    (cache/store result)  ;; Mixed concerns
    result))

;; DECOMPLECTED: Protocol abstraction
(defprotocol QueryExecutor
  (execute [this query]))

(defrecord DirectExecutor [db]
  QueryExecutor
  (execute [_ query] (db/query db query)))

(defrecord CachingExecutor [executor cache]
  QueryExecutor
  (execute [_ query]
    (or (cache/get cache query)
        (let [r (execute executor query)]
          (cache/store cache query r)
          r))))
```

### Pattern 3: Explicit Dependencies

```clojure
;; ENTANGLED: Hidden dependencies
(defn compile [q]
  (let [p (create-planner)        ;; Hardcoded
        config @global-config]    ;; Hidden!
    ...))

;; DECOMPLECTED: All dependencies explicit
(defn compile [q {:keys [planner optimizer]}]
  ;; No hidden state, testable with any inputs
  ...)
```

---

## Mutable State Requires User Approval

**⚠️ CRITICAL: Any mutable state (atom, volatile, ref, agent) is a decomplection violation unless explicitly approved by the user.**

Global mutable state is the #1 source of hidden dependencies. Before introducing ANY mutable construct:

1. **STOP** - Do not write the code yet
2. **ASK** - Request explicit user approval
3. **JUSTIFY** - Explain why pure design won't work
4. **DOCUMENT** - Include approval comment in code

```clojure
;; ❌ VIOLATION - atom without user approval
(defonce registry (atom {}))

;; ❌ VIOLATION - volatile without user approval
(defn compute [data]
  (let [result (volatile! [])]
    ...))

;; ✅ AFTER USER APPROVAL
;; MUTATION APPROVED (2025-02-05) by [user]:
;; Registry must be mutable for hot-reload component registration.
;; Isolated to registry module; all reads go through get-renderer.
(defonce registry (atom {}))
```

**See [clojure-coding-standards](../clojure-coding-standards/SKILL.md) for full approval workflow.**

---

## Recognizing Entanglement

**Red flags:**

1. **Hidden dependencies** - Function uses global state, atoms, or configs (REQUIRES USER APPROVAL)
2. **Mixed concerns** - Function does multiple unrelated things
3. **Hard to test** - Requires complex setup or mocking
4. **Can't reuse** - Function only works in one specific context
5. **Cascading changes** - Changing one thing requires changing many places

**Examples:**

```clojure
;; RED FLAG: Hidden dependency on global
(defn process-query [query]
  (let [schema @global-schema]  ;; Hidden!
    ...))

;; RED FLAG: Mixed concerns
(defn execute-query [query-string]
  (let [parsed (parse query-string)
        validated (validate parsed)
        result (execute validated)]
    result))

;; RED FLAG: Hard to test
(defn get-user [id]
  (or (cache-get id)
      (let [user (db-query id)]
        (cache-put id user)
        user)))
```

---

## When to Invest in Decomplection

Ask yourself:
- Will this be used in multiple places?
- Might this need different implementations?
- Is this core to the system?
- Will it change in the future?

**If yes to any: Decouple now.** Scripts and one-offs can be entangled.

---

## Implementation Checklist

Before committing, verify:

- [ ] No hidden dependencies (all inputs explicit)
- [ ] No mixed concerns (one responsibility)
- [ ] Easy to test (simple inputs, no setup)
- [ ] Reusable (REPL, tests, multiple contexts)
- [ ] Composable (output feeds into other functions)
- [ ] Pure or boundary-marked (! suffix for side effects)

**If any item fails: Ask "What would it take to decomplect this?"**

---

## Summary

1. **Simple beats easy** - Choose decomplected over familiar
2. **Explicit beats implicit** - All dependencies visible
3. **Composition beats entanglement** - Small pieces fit together
4. **Pure beats impure** - Side effects at boundaries
5. **Separate concerns** - One responsibility per function
6. **Test in isolation** - Each component provably correct

**For error handling decisions**, see [error-handling-patterns](../error-handling-patterns/) which covers the "fail fast > fallback > backward compatibility" hierarchy.
