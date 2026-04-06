---
name: decomplection-first-design
description: "Decomplection per Rich Hickey: simple = one fold (objective, about the artifact), easy = nearby (subjective, about the programmer). Complect = to braid together. State is never simple. DDRY = extracted code must be composable, not just not-repeated. Use when making design decisions, evaluating trade-offs, choosing approaches, extracting shared code, or reviewing for entanglement."
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

## Core Definitions (per Rich Hickey, "Simple Made Easy")

**Simple** (sim-plex: one fold/braid) = having one role, one concept, one dimension. Not interleaved with other things. Simple is an **objective** property of the artifact — you can look and see whether things are braided together. Simple is not about cardinality (having "only one thing") or about familiarity.

**Easy** (adjacent: to lie near) = nearby in three senses: at hand (installed), familiar (already known), near our capabilities (can we understand it). Easy is **relative** — easy for whom? When someone says "this is simple" but means "this is familiar to me," that conflation is the root cause of accidental complexity.

**Complex** (com-plex: braided together) = multiple things interleaved. The interleaving is what makes it hard to understand, change, and debug. Modularity does NOT imply simplicity — you can have separate modules that are completely complected through hidden dependencies.

**Complect** = to interleave, entwine, braid. The act of making things complex. Don't do it.

**Construct vs Artifact**: We evaluate constructs (the code we type) by ease of use, but we should evaluate them by the artifacts they produce (the running system over time). The user doesn't care how pleasant the code was to write — they care whether it works, can be debugged, and can be changed.

**State is never simple.** State fundamentally complects value and time. This complexity leaks through modularity boundaries — if a function returns different results for the same inputs, that complection poisons everything that touches it. State isn't just a risk to manage; it's an irreducible source of complection.

**Our choice**: Simple but hard > Easy but entangled. Always.

```
              Easy    | Hard
    ───────────────────────────
    Simple  | BEST    | OK
    ───────────────────────────
    Complex | BAD     | WORST
```

---

## Decomplection Decision Tree

When evaluating a design, ask these questions in order:

```
1. Does this have ONE role / ONE concept / ONE dimension?
   │
   ├─ NO → It's complected. What things are braided together?
   │        Unbraid them into separate, focused pieces.
   │
   └─ YES ↓

2. Are all dependencies explicit (no hidden state, globals, ambient context)?
   │
   ├─ NO → Make them explicit as arguments.
   │
   └─ YES ↓

3. Can I express this as a pure function (same inputs → same outputs)?
   │
   ├─ YES → Do it. This is simple.
   │
   └─ NO → Can I push effects to the boundary?
            │
            ├─ YES → Pure core + thin IO shell
            │
            └─ NO → Minimize complection. Document what's braided and why.
```

**Warning**: Don't confuse separation with simplicity. Putting complected code into separate modules doesn't make it simple — it just hides the braiding. The question is whether things are interleaved, not whether they're in different files.

---

## Four Core Patterns

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

### Pattern 4: DDRY (Decomplected Don't Repeat Yourself)

DRY alone is dangerous — it creates abstractions that braid unrelated concerns together just because they share some code. DDRY means: when you extract shared code, the result must be decomplected and composable.

```clojure
;; BAD DRY: extracted shared code, but it does three things for two callers
(defn process-entity [entity mode]
  (let [validated (validate entity)
        enriched (if (= mode :admin) (add-audit validated) validated)
        result (if (= mode :admin) (save-with-log enriched) (save enriched))]
    result))

;; DDRY: composable pieces, each with one role
(defn validate [entity] ...)
(defn add-audit [entity] ...)
(defn save [entity] ...)
(defn save-with-log [entity] (save (add-audit entity)))

;; Callers compose what they need
(comp save validate)              ;; regular path
(comp save-with-log validate)     ;; admin path
```

**The test**: When you extract shared code, does each piece have one role? Can callers compose them independently? If the shared function takes a `mode` or `type` parameter to switch behavior, it's DRY but not DDRY — split it.

---

## Mutable State Requires User Approval

**⚠️ CRITICAL: State is never simple.** It fundamentally complects value and time — you cannot get a value independent of when you ask. This complection leaks through every abstraction boundary: if the thing wrapping it is stateful, and the thing wrapping that is stateful, the complexity spreads like poison. No amount of modularity fixes this.

Any mutable state (atom, volatile, ref, agent) is a decomplection violation unless explicitly approved by the user. Before introducing ANY mutable construct:

1. **STOP** - Do not write the code yet
2. **ASK** - Present each atom to the user individually with a justification
3. **JUSTIFY** - Explain why a pure design won't work for this specific case
4. **WAIT** - The user decides. Do not self-approve.
5. **DOCUMENT** - After user approves, include approval comment in code

**Claude cannot approve mutable state.** Only the user can. Batch-stamping existing atoms with `MUTATION APPROVED` is not approval — it's rubber-stamping. Each atom must be individually justified and individually approved:

- Why can't this be a pure value?
- Could this be derived from existing state instead?
- Could this be an event or a parameter instead of stored state?
- What is the blast radius of this mutable state?

```clojure
;; ❌ VIOLATION - atom without user approval
(defonce registry (atom {}))

;; ❌ VIOLATION - Claude self-approved (not valid)
;; MUTATION APPROVED: needed for state management
(defonce registry (atom {}))

;; ✅ AFTER USER APPROVAL
;; MUTATION APPROVED (2025-02-05) by mark:
;; Registry must be mutable for hot-reload component registration.
;; Isolated to registry module; all reads go through get-renderer.
;; Pure alternative considered: passing registry as arg — rejected because
;; hot-reload requires stable reference across system restarts.
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

1. **Simple is objective, easy is relative** — evaluate the artifact, not the typing experience
2. **One fold** — each thing has one role, one concept, one dimension
3. **Complect is the enemy** — interleaving things is how complexity is born
4. **State is never simple** — it complects value and time; minimize it ruthlessly
5. **Explicit beats implicit** — all dependencies visible as arguments
6. **Composition beats entanglement** — place things together, don't braid them
7. **Modularity ≠ simplicity** — separate modules can still be complected
8. **DDRY over DRY** — extracted code must be decomplected and composable, not just not-repeated

**For error handling decisions**, see [error-handling-patterns](../error-handling-patterns/) which covers the "fail fast > fallback > backward compatibility" hierarchy.
