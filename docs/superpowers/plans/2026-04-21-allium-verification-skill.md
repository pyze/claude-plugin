# allium-verification Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a new `allium-verification` skill that guides Claude through using Chiasmus MCP to formally verify allium specs (Plan phase) and implementations against specs (Check phase).

**Architecture:** Single SKILL.md file in `skills/allium-verification/`. No code — this is a knowledge/workflow skill. The skill routes between two modes (Spec Verification and Implementation Verification) based on context and explicitly instructs Claude which Chiasmus tools to use and how to interpret results.

**Tech Stack:** Chiasmus MCP (already configured in `.mcp.json`), allium `.allium` file format, pyze-workflow skill conventions.

**Spec:** `docs/superpowers/specs/2026-04-21-allium-chiasmus-verification-design.md`

---

### Task 1: Create the allium-verification skill

**Files:**
- Create: `skills/allium-verification/SKILL.md`

- [ ] **Step 1: Create the skill directory and file**

Create `skills/allium-verification/SKILL.md` with this exact content:

```markdown
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

For each property:

- **PASS (UNSAT)**: `"✓ <property description> — UNSAT (no counterexample). Evidence: <Chiasmus output>"`
- **FAIL (SAT)**: `"✗ <property description> — SAT. Counterexample: <Chiasmus output>"`

**On any FAIL:** Stop immediately. Per CLAUDE.md, spec bugs require user input before any changes to the spec. Report the counterexample and ask the user whether the spec or the domain understanding is wrong.

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

If no traceability comments are found, stop and prompt the user to add them before proceeding.

### Workflow

**Step 1 — Read spec and locate implementation**

1. Read all `.allium` files — identify: surfaces, rules with `requires` guards, state machine transitions (entities with status enums and `transitions_to`/`becomes` triggers)
2. Search implementation files for traceability comments that reference these spec elements
3. Build a map: `<surface/rule name>` → `<implementation file(s)>`

**Step 2 — Verify surfaces (structural reachability)**

For each surface in the spec:

1. Identify the entry point (the function/route that corresponds to the surface's `provides` operation)
2. Identify the required handler (the function that enforces the surface's contract)
3. Call `chiasmus_graph` with a reachability query: "Does every call path from `<entry point>` pass through `<required handler>`?"

**Step 3 — Verify rules with `requires` guards (constraint matching)**

For each rule with `requires` clauses:

1. Identify the implementation's corresponding precondition check
2. Call `chiasmus_formalize`: "The implementation's precondition for `<rule name>` matches the spec's `requires` clause: `<requires text>`"
3. Fill slots with the implementation's actual constraint expressions
4. Call `chiasmus_verify` (Z3)

**Step 4 — Verify state machine transitions (Prolog)**

If the spec defines state machines (entities with status enums + transition rules):

1. List expected transitions from the spec: `{from_state, to_state, trigger_rule}` for each `transitions_to`/`becomes` rule
2. List actual transitions from the implementation (read the code)
3. Call `chiasmus_formalize`: "The implementation's state transitions exactly match the spec: no extra transitions, no missing transitions"
4. Call `chiasmus_verify` (Prolog) with `explain=true` to get derivation traces

**Step 5 — Report results**

For each verification:

- **PASS**: `"✓ <surface/rule> — <evidence string from Chiasmus>"`
- **FAIL**: `"✗ divergence at <surface/rule> — <Chiasmus output>"`

**On any FAIL:** Stop immediately.
- If the **code** is wrong: fix it directly
- If the **spec** is wrong: per CLAUDE.md, stop and get user input before modifying the spec

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
```

- [ ] **Step 2: Commit**

```bash
git add skills/allium-verification/SKILL.md
git commit -m "feat: add allium-verification skill (Chiasmus + allium integration)

New skill for formally verifying allium specs and implementations using
Chiasmus MCP tools. Two modes:
- Spec Verification (Plan phase): rule conflicts, invariant satisfiability,
  state machine completeness via Z3/Prolog
- Implementation Verification (Check phase): surface reachability via
  chiasmus_graph, rule preconditions and state transitions via
  chiasmus_verify

Part of issue #32 (pyze-workflow split).
"
```

---

### Task 2: Manual verification

No automated tests for markdown skills. Verify by reloading the plugin and triggering the skill.

- [ ] **Step 1: Reload plugins**

In Claude Code, run `/reload-plugins`. Confirm output includes the new skill — look for `allium-verification` in the skill list.

- [ ] **Step 2: Verify routing — Spec Verification mode**

Ask Claude: `"I have an allium spec with two rules that both fire when an order is confirmed. Are they consistent?"` — confirm the skill activates and routes to Mode 1 (Spec Verification), calls `chiasmus_formalize`, then `chiasmus_verify`.

- [ ] **Step 3: Verify routing — Implementation Verification mode**

Ask Claude: `"Does my implementation match my allium spec?"` — confirm the skill activates and routes to Mode 2 (Implementation Verification), looks for traceability comments, then calls `chiasmus_graph`.

- [ ] **Step 4: Verify skill boundaries section**

Ask Claude: `"I want to find drift between my spec and code"` — confirm it routes to `allium:weed`, not `allium-verification`.

- [ ] **Step 5: Commit if any fixes were needed**

```bash
git add skills/allium-verification/SKILL.md
git commit -m "fix: correct allium-verification skill routing"
```

(Skip this step if no fixes were needed.)
