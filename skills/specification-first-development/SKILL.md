---
name: specification-first-development
description: Write specifications before code to clarify requirements. Use when starting features with unclear requirements or complex business logic.
---

# Specification-First Development Skill

Specifications are the source of truth that drives implementation, not vice versa.

## Core Principle

**Code serves specifications.** Write specifications before code to preserve clear intent from requirements to implementation.

Behavioral specifications live in `.allium` files using the [Allium language](https://github.com/juxt/allium). Allium is implementation-agnostic — the same spec works regardless of language or framework.

---

## Skill Boundary

This skill covers: **When/what to specify** — deciding if specs are needed, which allium skill to use, and how to write them.

**Use DIFFERENT skill if:**
- Where to store documentation → [documentation-maintenance](../documentation-maintenance/)
- Recording discoveries → [learning-capture](../learning-capture/)
- Converting spec examples to tests → [bdd-scenarios](../bdd-scenarios/)

**Pipeline:** `allium:elicit` → `.allium` spec → `allium:propagate` → BDD scenarios ([bdd-scenarios](../bdd-scenarios/)) → TDD (`superpowers:test-driven-development`).

---

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

## Specification Format

Specs live in `.allium` files. Allium captures observable behavior — what the system does — without prescribing implementation.

**Starting a spec:** Use the `allium:elicit` skill to build a spec through structured conversation, or `allium:distill` to extract a spec from existing code.

### Example: Authentication Surface

```allium
entity User {
    email: Email
    password: HashedPassword
    status: active | suspended
}

surface Authenticate {
    facing client: ApiClient

    provides:
        Login(email: Email, password: PlainPassword)

    @guarantee authenticated
        A successful login returns a valid session token scoped to the user.

    @guarantee rejected
        An unrecognized email or wrong password returns an error without
        revealing which check failed.
}

rule IssueSession {
    when: Login(email, password)
    requires: user: User where email = email and password matches user.password
    ensures: Session.created(user: user, token: fresh_token())
}

rule RejectLogin {
    when: Login(email, password)
    requires: not (user: User where email = email and password matches user.password)
    ensures: LoginFailed(reason: invalid_credentials)
}
```

### Key Allium Constructs

**Entity** — domain object with fields, relationships, and derived values:
```allium
entity Order {
    customer: Customer
    items: List<LineItem>
    status: pending | confirmed | shipped | cancelled
    total: sum(items.price)
}
```

**Rule** — behavioral specification with trigger, guards, and outcomes:
```allium
rule ConfirmOrder {
    when: CustomerConfirmsOrder(order)
    requires: order.status = pending
    requires: order.items.count > 0
    ensures: order.status = confirmed
    ensures: OrderConfirmed(order)
}
```

**Surface** — boundary contract between actors and domain:
```allium
surface OrderCheckout {
    facing buyer: Customer

    context cart: Order where customer = buyer and status = pending

    exposes:
        cart.items
        cart.total

    provides:
        CustomerConfirmsOrder(cart)
            when cart.items.count > 0
}
```

For full syntax reference, see the `allium` skill.

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

**Document open questions as allium comments:**

```allium
-- [?] Token expiration: 24 hours or 7 days? Pending user clarification.
rule IssueSession {
    ...
}
```

---

## 4-Phase Workflow

### Phase 1: Specify

1. **Choose entry point:**
   - **New feature** → invoke `allium:elicit` to build spec through structured conversation
   - **Existing code** → invoke `allium:distill` to extract spec from implementation
2. Write or review the resulting `.allium` file
3. Identify open questions and mark with `-- [?]`
4. **Ask user to clarify ONE question at a time**

### Phase 2: Research

5. Validate assumptions at REPL or by reading code
6. Discover technical constraints
7. **If constraints conflict with spec:** ask user for priority
8. Update spec using `allium:tend` — do not edit `.allium` files directly for structural changes

### Phase 3: Implement

9. Code implements the allium spec's surfaces and rules
10. Link code to spec surface/rule names in comments:
    ```python
    # Implements: Authenticate surface, IssueSession rule
    def login(email: str, password: str) -> Session: ...
    ```
11. **If implementation reveals ambiguity:** STOP and ask, then update spec with `allium:tend`

### Phase 4: Verify

12. Run `allium:propagate` to generate test obligations from the spec
13. Use those test obligations as input to [bdd-scenarios](../bdd-scenarios/) for Given/When/Then scenarios
14. Run `allium:weed` to detect divergence between spec and implementation
15. Fix divergences in spec OR code — never let them drift

---

## Traceability

**Link every module to its allium spec:**

```typescript
// Implements: specs/auth.allium
// Surfaces: Authenticate
// Rules: IssueSession, RejectLogin
export async function login(email: string, password: string): Promise<Session> { ... }
```

```clojure
;; Implements: specs/order.allium
;; Surface: OrderCheckout
;; Rule: ConfirmOrder
(defn confirm-order [order] ...)
```

---

## Living Documents

**Bidirectional updates — specs and code stay synchronized:**

```
Requirements change?
    │
    ├─ Update spec FIRST with allium:tend
    ├─ Review changes (one question at a time)
    └─ Then update code to match

Implementation reveals issues?
    │
    ├─ Mark in spec with -- [?] comment
    ├─ Ask user to clarify conflicts
    ├─ Update spec with allium:tend
    └─ Update code to match refined spec

Periodic check:
    └─ Run allium:weed to surface any drift
```

---

## Anti-Patterns

- **Don't**: Write vague specs ("handle errors appropriately")
- **Don't**: Skip spec for "obvious" features (>30 min = needs spec)
- **Don't**: Implement before resolving spec ambiguities
- **Don't**: Write spec after implementation (defeats purpose)
- **Don't**: Let spec and code drift — run `allium:weed` regularly

---

## Summary

1. **Specifications before code** — define observable behavior in `.allium` first
2. **Use allium skills** — `elicit` to discover, `distill` from code, `tend` to update, `propagate` for tests, `weed` for divergence
3. **Ask ONE question at a time** — resolve ambiguities clearly
4. **Don't assume** — validate uncertainties with user
5. **4-phase workflow** — Specify → Research → Implement → Verify
6. **Traceability** — link code comments to spec surface/rule names
7. **Living documents** — spec ↔ code stay synchronized via `allium:weed`
8. **Tests from spec** — use `allium:propagate` to generate test obligations
