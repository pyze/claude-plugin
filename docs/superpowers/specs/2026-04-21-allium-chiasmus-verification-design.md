# Design: allium-verification Skill (Chiasmus + Allium Integration)

**Date:** 2026-04-21
**Status:** Approved

## Context

pyze-workflow now includes allium as a standard companion plugin. The `specification-first-development` skill uses `.allium` files as the authoritative behavioral spec. This design adds formal verification of those specs using the Chiasmus MCP (Z3, Prolog, call graph analysis).

The goal is to prove properties rather than spot-check them:
- **Plan phase**: prove the allium spec is internally sound before implementation begins
- **Check phase**: prove the implementation honors the allium spec's contracts

## Skill Identity

- **Name**: `allium-verification`
- **Location**: `skills/allium-verification/SKILL.md`
- **Trigger description**: "Verify allium specs with Chiasmus. Use when you want to check a `.allium` spec for internal consistency (Plan phase), or verify that an implementation honors an allium spec (Check phase)."
- **Auto-triggers**: `**/*.allium` file patterns; keywords: "verify spec", "chiasmus allium", "spec consistent"
- **Invocation**: manual/on-demand skill — no hooks

## Relationship to Existing Skills

| Skill | Purpose | Difference |
|-------|---------|------------|
| `formal-verification` | Prove /derisk assumptions (Z3/Prolog/call graph) | General-purpose; not allium-aware |
| `allium:weed` | Find spec/code divergences by reading | Reading-based; not proof-based |
| `allium:propagate` | Generate test cases from spec | Covers specific inputs; not universal properties |
| `allium-verification` (this) | Prove allium spec properties formally | Allium-specific; proves for all inputs |

## Phase 1: Spec Verification (Plan)

**When**: after `allium:elicit` or `allium:tend`, before ExitPlanMode.

**Goal**: prove the `.allium` spec is internally sound — no implementation required.

### Workflow

1. Read all `.allium` files in the project
2. Scan for verifiable properties:
   - **Rule conflicts**: two rules with overlapping `when` triggers that produce contradictory `ensures`
   - **Invariants**: declared `invariant` blocks — check satisfiability (not self-contradictory)
   - **State machines**: entities with status enums and `transitions_to`/`becomes` rules — check no dead states, all states reachable from initial
3. For each property:
   - `chiasmus_formalize` — describe the property in natural language; get the matching template and slots
   - Fill slots from the allium spec
   - `chiasmus_verify` — run verification
4. Report:
   - **PASS**: "Spec verified: `<property>` — UNSAT (no counterexample)" with Chiasmus evidence
   - **FAIL**: show counterexample; per CLAUDE.md, stop and get user input before modifying the spec

### Scope Boundary

- Verifies spec against *itself* only — no implementation files read
- If no `.allium` files exist, skip silently
- Spec bugs (FAIL result) require user input before any changes

## Phase 2: Implementation Verification (Check)

**When**: implementation is complete, before marking issue done or transitioning to Check phase.

**Goal**: prove the implementation structurally honors the allium spec's surfaces and rules.

### Workflow

1. Read `.allium` files — identify surfaces, rules with `requires` guards, state machine transitions
2. Find implementation files via traceability comments (e.g., `// Implements: specs/auth.allium, Surface: Authenticate`)
3. For each **surface**:
   - `chiasmus_graph` — reachability analysis: does every entry point route through the required handler?
4. For each **rule** with `requires` guards:
   - `chiasmus_formalize` + `chiasmus_verify` (Z3) — do the implementation's precondition checks match the spec's `requires` clauses?
5. For **state machines**:
   - `chiasmus_verify` (Prolog) — do code transitions match spec transitions exactly? No extra, no missing.
6. Report:
   - **PASS**: property-by-property evidence log
   - **FAIL**: "divergence at `<surface/rule>`" — code bugs can be fixed immediately; spec bugs require user input per CLAUDE.md

### Scope Boundary

- Requires traceability comments in code (from `specification-first-development` skill)
- If no traceability comments found, prompt user to add them before proceeding

## Routing Table

| Situation | Mode | Key Chiasmus Tools |
|-----------|------|--------------------|
| Reviewing/updating a `.allium` spec | Spec Verification | `chiasmus_formalize` + `chiasmus_verify` |
| About to exit plan mode, `.allium` files present | Spec Verification | `chiasmus_formalize` + `chiasmus_verify` |
| Implementation done, checking against spec | Implementation Verification | `chiasmus_graph` + `chiasmus_verify` |
| "Do these rules conflict?" | Spec Verification | `chiasmus_formalize` + `chiasmus_verify` |
| "Does my code match the spec?" | Implementation Verification | `chiasmus_graph` + `chiasmus_verify` |

## Evidence Format

Consistent with `formal-verification` skill:

```
PASS — chiasmus_verify: UNSAT — no counterexample for <property> (<spec file>:<rule/invariant name>)
FAIL — chiasmus_verify: SAT — counterexample: <specific failing case>
PASS — chiasmus_graph: all paths from <entry> to <handler> verified reachable
FAIL — chiasmus_graph: path found bypassing <handler> via <call chain>
```

## Non-Goals

- Does not replace `allium:weed` — weed catches semantic drift by reading; this proves structural properties formally
- Does not replace `allium:propagate` — propagate generates test obligations; this proves universal properties
- Does not add hooks or automatic gates — invoked on-demand as a skill
