---
name: formal-verification
description: "Formally verify plan assumptions using Chiasmus MCP (Z3 solver, Prolog, call graph). Use when /derisk has assumptions about consistency, reachability, state machines, business rules, or RBAC that can be proven rather than spot-checked."
---

# Formal Verification with Chiasmus

Use Chiasmus MCP tools to **prove** assumptions rather than spot-check them. A REPL test shows one case works; formal verification shows all cases work (or finds a counterexample).

## When to Use This Skill

**Use THIS skill if:**
- An assumption is about **consistency** ("these validations never conflict")
- An assumption is about **reachability** ("user input can't reach this query without sanitization")
- An assumption is about **state machines** ("this workflow can't get stuck in a dead state")
- An assumption is about **business rules** ("RBAC rules never allow and deny the same action")
- An assumption is about **exhaustive properties** ("every code path handles this error")

**Use REPL instead if:**
- You need to check a specific value or return shape
- You're validating a single code path
- The assumption is about runtime behavior (performance, timing)

**Use grep/LSP instead if:**
- You're checking whether a function exists or is referenced
- You're counting usages or finding call sites

---

## Core Tools

### chiasmus_formalize — Find the right verification approach

Start here. Describe what you want to verify in natural language. Chiasmus matches it to a template and tells you how to fill in the slots.

```
Input:  "RBAC rules never allow and deny the same action for the same role"
Output: Template with slots for roles, actions, resources, allow rules, deny rules
```

**When to use:** Before writing any formal spec. Let the tool suggest the approach.

### chiasmus_verify — Run the verification

Submit a filled specification (SMT-LIB for Z3, or Prolog). Returns either:
- **Satisfiable** + counterexample (the assumption is WRONG — here's a case that breaks it)
- **Unsatisfiable** (the assumption is PROVEN — no counterexample exists)

For Prolog, use `explain=true` to get derivation traces showing why a result holds.

### chiasmus_graph — Structural code verification

For assumptions about code structure (reachability, dead code, impact). See `/code-cleanup` for full usage — but in a `/derisk` context:

- "Function X can't be called without going through middleware Y" → reachability analysis
- "Changing function Z only affects module A" → impact analysis
- "This refactoring doesn't leave dead code" → dead code detection

---

## Verification Patterns for /derisk

### Pattern 1: Consistency ("rules never conflict")

**Assumption:** "Validation rules on frontend and backend never produce different results for the same input."

**Approach:** Model both rule sets as Z3 constraints. Ask: is there an input where frontend says valid and backend says invalid (or vice versa)?

```
1. chiasmus_formalize: "Two validation rule sets never disagree on the same input"
2. Fill slots with actual frontend rules and backend rules
3. chiasmus_verify: If UNSAT → proven consistent. If SAT → counterexample shows the disagreeing input.
```

**Risk assessment update:**
- SAT (counterexample found) → RISK: HIGH, EVIDENCE: "Formal verification found conflicting input: {counterexample}"
- UNSAT (proven) → RISK: NONE, EVIDENCE: "Formally verified: no input produces different results"

### Pattern 2: Reachability ("X can't happen without Y")

**Assumption:** "User input reaches the database query only through the sanitization middleware."

**Approach:** Use `chiasmus_graph` for call graph reachability, or Prolog for logical path analysis.

```
1. chiasmus_graph: reachability analysis from user-input entry points to db-query function
2. Check if any path bypasses the sanitization function
```

**Risk assessment update:**
- Path found bypassing sanitization → RISK: HIGH (security)
- All paths go through sanitization → RISK: NONE, EVIDENCE: "Call graph analysis: all paths from {entry} to {query} traverse {sanitizer}"

### Pattern 3: State Machines ("no dead states")

**Assumption:** "The workflow state machine can always reach a terminal state from any reachable state."

**Approach:** Model states and transitions in Prolog. Query for reachable states that have no outgoing transitions to a terminal state.

```
1. chiasmus_formalize: "State machine has no dead-end states"
2. Fill slots with states, transitions, and terminal states
3. chiasmus_verify (Prolog): Query for dead-end states
```

**Risk assessment update:**
- Dead-end states found → RISK: HIGH, EVIDENCE: "State {X} has no path to terminal"
- No dead-end states → RISK: NONE, EVIDENCE: "Formally verified: all reachable states can reach terminal"

### Pattern 4: Business Rules ("permissions are sound")

**Assumption:** "No user can both approve and submit the same request."

**Approach:** Model RBAC as Z3 constraints. Ask: is there a user/role/request where both approve and submit are granted?

```
1. chiasmus_formalize: "RBAC separation of duties — no user has both approve and submit"
2. Fill slots with role definitions, permission assignments
3. chiasmus_verify: SAT = violation found, UNSAT = proven sound
```

### Pattern 5: Data Model Invariants

**Assumption:** "Every order has at least one line item after normalization."

**Approach:** Model the normalization function's postconditions as Z3 assertions. Check if a valid input can produce an empty line items collection.

---

## Decision: When to Formally Verify vs REPL Check

```
Is the assumption about ALL possible cases?
│
├─ YES (consistency, exhaustive, "never", "always")
│   → Formal verification. REPL shows one case; Z3/Prolog proves all cases.
│
└─ NO (specific behavior, one code path, runtime value)
    → REPL check is sufficient.
```

**Cost rule:** If formalization takes more than 10 minutes and the assumption is LOW impact, REPL-check it instead. Formal verification is most valuable for HIGH impact assumptions where "probably works" isn't good enough.

---

## Integration with /derisk

When running `/derisk`, for each unvalidated assumption:

1. Check if it's a consistency/reachability/exhaustive property → if yes, consider formal verification
2. Call `chiasmus_formalize` to see if a template matches
3. If a template matches and the assumption is MEDIUM+ impact → verify formally
4. Update RISK and EVIDENCE with the formal result

**Evidence format for formal verification:**
```
- EVIDENCE: Formally verified via Z3 — UNSAT (no counterexample exists for {property})
- EVIDENCE: Formally verified via Prolog — all reachable states can reach terminal (explain trace attached)
- EVIDENCE: Formal verification found counterexample: {specific failing case}
```

This is stronger evidence than REPL spot-checks. A formally verified assumption can be NONE risk even for HIGH impact properties.
