---
name: allium-verification
description: "Formally verify allium specs with Chiasmus. Use when you want to check a .allium spec for internal consistency (Plan phase), or verify that an implementation honors an allium spec (Check phase)."
---

# Allium Verification with Chiasmus

Use Chiasmus MCP tools to **prove** allium spec properties rather than spot-check them. `allium:weed` finds divergences by reading; this skill proves them (or disproves them) for all possible inputs.

## Routing

| Situation | Mode |
|-----------|------|
| Reviewing or updating a `.allium` spec (Plan phase) | Spec Verification |
| About to exit plan mode and `.allium` files exist | Spec Verification |
| "Do these rules conflict?" | Spec Verification |
| Implementation is done, verifying against spec (Check phase) | Implementation Verification |
| "Does my code match the spec?" | Implementation Verification |

---

## Mode 1: Spec Verification (Plan Phase)

**Goal:** Prove the `.allium` spec is internally sound before implementation begins.

### When to use

After `allium:elicit` or `allium:tend`, before committing to an implementation plan.

### Workflow

**Step 1 — Find and read `.allium` files**

Search the project for all `.allium` files. If none exist, exit silently.

**Step 2 — Identify verifiable properties**

Scan each spec for:

- **Rule conflicts**: two or more rules whose `when` triggers can fire simultaneously and whose `ensures` clauses contradict each other (e.g., both set `order.status` to different values)
- **Invariant satisfiability**: any `invariant` block — check it is not self-contradictory (i.e., there exists at least one valid system state satisfying it)
- **State machine completeness**: entities with `status: A | B | C` enums combined with `transitions_to`/`becomes` rules — check that every non-terminal state has at least one outgoing transition path to a terminal state (no dead ends)

If none of these constructs are present in the spec, report "no formally verifiable properties found" and exit.

**Step 3 — Verify each property**

For each property identified in Step 2:

1. Call `chiasmus_formalize` with a natural language description of the property. Example descriptions:
   - Rule conflict: "Rules `<RuleA>` and `<RuleB>` cannot both fire and produce contradictory outcomes for `<entity>.<field>`"
   - Invariant: "The invariant `<invariant name>` is satisfiable — there exists a valid system state where it holds"
   - State machine: "Every state in `<Entity>.status` can reach a terminal state via available transitions"
2. Fill the template slots using values from the `.allium` spec
3. Call `chiasmus_verify` with the filled specification

**Step 4 — Report results**

The SAT/UNSAT interpretation depends on the property type:

| Property type | PASS result | FAIL result |
|---------------|-------------|-------------|
| Rule conflict | UNSAT — no conflicting case exists | SAT — counterexample found |
| Invariant satisfiability | SAT — a valid state exists | UNSAT — no valid state, invariant is self-contradictory |
| State machine completeness | UNSAT — no dead-end state exists | SAT — dead-end state found |

Report each property using the correct interpretation:

- **PASS**: `"✓ <property description> — <UNSAT/SAT per table above>. Evidence: <Chiasmus output>"`
- **FAIL**: `"✗ <property description> — <SAT/UNSAT per table above>. <counterexample or explanation>"`

**On any FAIL:** Stop immediately. Per CLAUDE.md, spec bugs require user input before any changes to the spec. Report the result and ask the user whether the spec or the domain understanding is wrong.

---

## Mode 2: Implementation Verification (Check Phase)

**Goal:** Prove the implementation structurally honors the allium spec's surfaces and rules.

### Prerequisites

Implementation files must contain traceability comments added by `specification-first-development`, e.g.:
```
// Implements: specs/auth.allium
// Surfaces: Authenticate
// Rules: IssueSession, RejectLogin
```

If no traceability comments are found in any file, stop and prompt the user to add them before proceeding. If only some files have traceability comments, proceed with the covered files and note which files were skipped due to missing traceability in the Step 5 report.

### Workflow

**Step 1 — Read spec and locate implementation**

1. Read all `.allium` files — identify: surfaces, rules with `requires` guards, state machine transitions (entities with status enums and `transitions_to`/`becomes` triggers)
2. Search implementation files for traceability comments that reference these spec elements
3. Build a map: `<surface/rule name>` → `<implementation file(s)>`

**Step 2 — Verify surfaces (structural reachability)**

For each surface in the spec:

1. Identify the entry point (the function/route that corresponds to the surface's `provides` operation)
2. Identify the required handler (the function that enforces the surface's contract)
3. Call `chiasmus_graph` with structured parameters:
   - `files`: the implementation files found in Step 1 for this surface
   - `analysis`: `"reachability"`
   - `from`: the entry point function name
   - `to`: the required handler function name
4. Interpret result: if all paths from `from` reach `to` → PASS; if any path bypasses `to` → FAIL

**Step 3 — Verify rules with `requires` guards (constraint matching)**

For each rule with `requires` clauses:

1. Identify the implementation's corresponding precondition check
2. Call `chiasmus_formalize`: "The implementation's precondition for `<rule name>` matches the spec's `requires` clause: `<requires text>`"
3. Fill slots with the implementation's actual constraint expressions
4. Call `chiasmus_verify` (`chiasmus_formalize` will have returned a Z3/SMT-LIB template for this property type)

**Step 4 — Verify state machine transitions (Prolog)**

If the spec defines state machines (entities with status enums + transition rules):

1. List expected transitions from the spec: `{from_state, to_state, trigger_rule}` for each `transitions_to`/`becomes` rule
2. List actual transitions from the implementation (read the code)
3. Call `chiasmus_formalize`: "The implementation's state transitions exactly match the spec: no extra transitions, no missing transitions"
4. Call `chiasmus_verify` with `explain=true` to get derivation traces (`chiasmus_formalize` will have returned a Prolog template for state machine queries)

**Step 5 — Report results**

For each verification:

- **PASS**: `"✓ <surface/rule> — <evidence string from Chiasmus>"`
- **FAIL**: `"✗ divergence at <surface/rule> — <Chiasmus output>"`

**On any FAIL:** Stop immediately.
- If the **code** is wrong: fix it directly
- If the **spec** is wrong: per CLAUDE.md, stop and get user input before modifying the spec

**Triage rule:** Assume the code is wrong unless the Chiasmus counterexample reveals a scenario the spec has no rule for (i.e., the case is simply unmodeled). If the counterexample corresponds to a real input that the spec's `requires` guards would accept but no `ensures` rule handles, the spec is incomplete — stop and get user input.

---

## Evidence Format

Use this format consistently so results can be referenced in risk assessments:

```
✓ PASS — chiasmus_verify: UNSAT — no counterexample for <property> (<file>:<name>)
✗ FAIL — chiasmus_verify: SAT — counterexample: <specific failing case>
✓ PASS — chiasmus_graph: all paths from <entry> to <handler> verified reachable
✗ FAIL — chiasmus_graph: path found bypassing <handler> via <call chain>
```

---

## Skill Boundaries

**Use this skill for:** formal proof of allium spec properties and implementation contracts

**Use `allium:weed` instead if:** you want to find spec/code drift by reading and comparing (faster, less rigorous)

**Use `allium:propagate` instead if:** you want to generate concrete test cases from the spec

**Use `formal-verification` instead if:** you want to prove a general `/derisk` assumption not related to an allium spec
