---
name: derisk
description: "Risk analysis: identify options, validate assumptions at REPL"
---

# /derisk

Report implementation options with their unvalidated assumptions, then validate critical assumptions at the REPL.

**Load the [risk-assessment](../skills/risk-assessment/) skill before proceeding.** It defines how to evaluate and assign risk levels. Non-negotiable rules:

- **Unvalidated = MEDIUM minimum.** If you haven't checked, it's not LOW.
- **Overall = max.** One MEDIUM makes the overall MEDIUM. One HIGH makes overall HIGH.
- **Assessment is not a TODO list.** "Need to check X" is not evidence — check it now.
- **No compound assumptions.** Parenthetical claims like "(which is dead)" are hidden assumptions that need their own validation.
- **No mitigation-as-assessment.** "If X fails, we can do Y" is a fallback plan, not a risk level reduction.
- **Partial validation ≠ LOW.** "Works for simple cases" on a correctness property is MEDIUM until comprehensively tested.

This command helps identify what needs validation before implementing plans by analyzing multiple approaches and highlighting unsupported assumptions for each option. Particularly useful for state management decisions, effect ordering, and API integration patterns.

## How It Works

Given the context provided as an argument, do this:

### 1. Find the Most Recent Plan

- Search conversation history for recent plan presentations
- Check scratchpad for stored plans or implementation strategies
- Look for plan-related paths in scratchpad like `["plan-risks"]`, `["plan-unknowns"]`

### 2. Identify Implementation Options

- List 2-3 viable implementation approaches for the plan
- For each option, briefly note pros/cons and complexity
- Identify option-specific assumptions and risks
- Note shared assumptions that apply to all approaches

**Example:** For "implement user settings feature":
- **Option 1**: Store in normalized state, sync via HTTP
- **Option 2**: Store in localStorage, lazy sync on navigation
- **Option 3**: Hybrid - normalized state for active use, localStorage for persistence

### 3. Report Unvalidated Assumptions

Organize assumptions by category:
- **Overall Plan Assumptions** - Common to all approaches
- **Option 1 Assumptions** - Specific to first approach
- **Option 2 Assumptions** - Specific to second approach
- **Option 3 Assumptions** - Specific to third approach (if applicable)

Mark which assumptions have **NO supporting evidence**:

```
ASSUMPTION: State store lookup returns expected entity shape
STATUS: No supporting evidence

ASSUMPTION: HTTP handler applies state updates before success callback
STATUS: No supporting evidence

ASSUMPTION: Effects execute in dispatch order
STATUS: Supported (verified in codebase)
```

Prioritize assumptions without evidence as high-risk. Include:
- Dependencies on library behavior (state normalization, event dispatch)
- External system assumptions (API response format)
- Performance characteristics (memory, latency)
- Correctness properties (ordering, uniqueness)

### 4. Validate Critical Assumptions

Prioritize assumptions that affect option selection or feasibility. Choose the right validation tool:

**REPL** — for specific values, return shapes, single code paths:
1. Load namespaces, run queries
2. Verify state store behavior, event dispatch, HTTP handlers
3. Check function signatures and return types

**Formal verification (Chiasmus)** — for exhaustive properties ("never", "always", "all paths"):
1. Call `chiasmus_formalize` with the assumption in natural language
2. Fill template slots with actual rules/states from the codebase
3. Run `chiasmus_verify` — UNSAT = proven, SAT = counterexample found
4. Use `chiasmus_graph` for reachability and impact assumptions

See [formal-verification](../skills/formal-verification/) for patterns and decision tree.

**Grep/LSP** — for existence checks, reference counting, call sites

### 5. Ask User Questions for Non-Determinable Information

After REPL exploration, identify remaining unknowns:

1. Ask questions **ONE AT A TIME**
2. Wait for user response before next question
3. Make questions specific and actionable
4. Format: `**Question N: [Topic]** [Specific question with context and implications]`
5. Update assumptions based on answers

### 6. Document Findings

Store findings at `["plan-risks", "option-analysis"]` and `["plan-risks", "explored-findings"]`:

**For each option:**
```clojure
{:option "Option 1: Normalized state with HTTP sync"
 :pros ["Consistent with existing patterns" "Normalized store"]
 :cons ["Requires server roundtrip" "More complex error handling"]
 :risk-level "LOW"
 :assumptions-validated ["add-entity normalizes" "pull-entity returns expected shape"]
 :assumptions-unknown ["sync timing on navigation"]}
```

### 7. Provide Updated Risk Assessment with Recommendation

- Compare risk levels between all options
- Recommend the best option based on validated evidence
- Highlight critical discoveries that change the plan
- Categorize remaining risks by level (NONE/LOW/MEDIUM/HIGH)
- Note confidence level in recommended option

### 8. No Overall Risk Level

The ExitPlanMode gate checks each `RISK:` line individually. Any MEDIUM or HIGH blocks until resolved or ACCEPTED by the user. Do not compute or write an "Overall risk level" line — each assumption stands on its own.

### 9. Handle Optional Arguments

- Use `$ARGUMENTS` for additional context or focus areas
- If specific assumptions mentioned, prioritize those
- Append any user-provided context to exploration scope

## Common Clojure Assumptions to Validate

### Integrant Lifecycle
- Does service initialization order match refs?
- Is cleanup (halt!) called when system restarts?
- Can services be hot-reloaded during development?

### Protocol Dispatch
- Does the protocol have implementations for all expected types?
- Are multimethods dispatching on the expected key/value?
- Is `prefer-method` needed for ambiguous hierarchies?

### Namespace Loading
- Are all required namespaces loaded before use?
- Do circular dependencies exist between namespaces?
- Are reader conditionals handling CLJ/CLJS correctly?

### Data Shape Validation
- Does the function return the expected shape?
- Are optional keys handled correctly (nil vs missing)?
- Does destructuring match the actual data structure?

## Typical Derisk Workflow

```bash
# 1. Before implementing, validate assumptions
/derisk
# → Shows 2-3 options with unvalidated assumptions
# → Validates critical ones at REPL
# → Asks clarifying questions
# → Recommends lowest-risk approach

# 2. Implement with confidence
# (proceed with chosen approach)
```
