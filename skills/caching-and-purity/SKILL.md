---
name: caching-and-purity
description: Reason correctly about caching and referential transparency. Use when deciding whether to add caching, evaluating function purity for cacheability, diagnosing stale cache results, or understanding why a cached function returns wrong data.
---

# Caching and Purity

## The Principle

**Caching is enabled by purity. It never conflicts with it.**

A pure function is referentially transparent: for the same inputs it always produces the same output. This property is precisely what makes caching valid --- you can replace a function call with its cached result and the program's meaning does not change.

```
Pure function + cache = correct optimization
Impure function + cache = bug
```

**Caching does not break purity.** Caching does not violate referential transparency. If a cached function returns stale or incorrect results, the function was never pure to begin with. The cache merely exposed a pre-existing impurity.

## Diagnostic Rule

When caching produces wrong results, ask:

> What input does this function's output depend on that is NOT captured in the cache key?

The answer identifies the hidden dependency --- the source of impurity. The cache is the messenger, not the cause.

## Two Remedies

Once you've identified the hidden dependency:

### Remedy 1: Make the function pure (preferred)

Include all dependencies in the function's explicit inputs. The cache key then captures everything the output depends on, and caching becomes correct.

```clojure
;; IMPURE: output depends on external state not in inputs
(defn resolve-value [_ {:keys [var-name]}]
  (let [entity (lookup-in-mutable-db var-name)]  ;; hidden dependency
    {:value (:control/value entity)}))

;; PURE: all dependencies are explicit inputs
(defn resolve-value [_ {:keys [var-name entity]}]
  {:value (:control/value entity)})
```

### Remedy 2: Disable caching (workaround)

When you cannot make all dependencies explicit (e.g., framework constraints prevent it), disable caching. This acknowledges the impurity rather than pretending it doesn't exist.

**Remedy 1 is always preferred.** Remedy 2 is a pragmatic concession when architecture constrains you.

## Reasoning Checklist

Before caching any function:

1. **List all dependencies** --- What does the output depend on? Inputs, closed-over state, external reads?
2. **Check the cache key** --- Does the cache key capture *every* dependency?
3. **If yes** --- Caching is safe. The function is pure with respect to the cache key.
4. **If no** --- Either make the missing dependency explicit in the key (Remedy 1) or disable caching (Remedy 2).

## Anti-Patterns

| Thought | Problem |
|---------|---------|
| "Caching broke this" | Caching exposed an impurity. Find the hidden dependency. |
| "Disable the cache to fix purity" | Disabling cache doesn't restore purity; it avoids the *consequence* of impurity. |
| "This is cheap, so caching is unnecessary" | Cost is orthogonal. The question is correctness: is the function pure w.r.t. the cache key? |
| "Add cache-bypass everywhere to be safe" | Over-broad. Only impure functions need it. Pure functions benefit from caching. |

## Related Skills

- [decomplection-first-design](../decomplection-first-design/) --- Hidden dependencies are a decomplection violation
- [clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md](../clojure-coding-standards/FUNCTIONAL-PRINCIPLES.md) --- Pure function conventions
