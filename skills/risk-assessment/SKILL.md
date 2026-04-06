---
name: risk-assessment
description: "Evaluate risk levels for plan assumptions and code changes. Use when assessing NONE/LOW/MEDIUM/HIGH risk, writing ## Risk Assessment sections, running /derisk, or deciding whether an assumption needs validation."
---

# Risk Assessment Skill

How to evaluate and assign risk levels for plan assumptions and code changes.

## When to Use This Skill

- Writing `## Risk Assessment` sections in plans
- Running `/derisk` to validate assumptions
- Deciding whether an assumption needs validation before proceeding
- Evaluating the impact of unexpected discoveries during Do phase

---

## Core Rule: Unvalidated ≠ LOW

**If you haven't verified an assumption, you don't know its risk.** An unvalidated assumption is MEDIUM at minimum. You cannot assign LOW or NONE to something you haven't checked.

```
Validated + unlikely to break     → NONE
Validated + minor impact if wrong → LOW
NOT validated                     → MEDIUM (at minimum)
NOT validated + high impact       → HIGH
```

**There is no shortcut.** "I think it's probably fine" is not validation. Validation means: checked at the REPL, grepped the codebase, read the source, or confirmed with the user.

---

## Validation Cost Rule

If validating an assumption takes less than 30 seconds, **validate it now**. Don't mark it unvalidated and move on.

| Validation method | Typical cost | Examples |
|------------------|-------------|---------|
| Grep/Glob | < 5 seconds | "Is this function used elsewhere?" "Is this namespace required by anything?" |
| REPL evaluation | < 30 seconds | "Does this API return the expected shape?" "Does this protocol have this method?" |
| Read source | < 1 minute | "What does this function actually do?" "What config does this key expect?" |
| Run tests | 1-5 minutes | "Do existing tests still pass with this change?" |
| User question | Variable | "Is this the intended behavior?" "Should this be backwards-compatible?" |

If the cost is < 30 seconds, there is **no excuse** for marking it unvalidated.

---

## Risk Matrix: Impact × Likelihood

| | Low likelihood | Medium likelihood | High likelihood |
|---|---|---|---|
| **High impact** | MEDIUM | HIGH | HIGH |
| **Medium impact** | LOW | MEDIUM | HIGH |
| **Low impact** | NONE | LOW | MEDIUM |

### Assessing Impact

What breaks if this assumption is wrong?

| Impact level | Criteria |
|-------------|----------|
| **High** | Build breaks. Data corruption. Security vulnerability. User-facing feature broken. Shared component affected (high blast radius). |
| **Medium** | One feature broken. Test failures. Performance degradation. Developer workflow disrupted. |
| **Low** | Cosmetic issue. Minor inconvenience. Easily caught in review. Affects only dead/unused code. |

### Assessing Likelihood

How likely is the assumption to be wrong?

| Likelihood | Criteria |
|-----------|----------|
| **High** | Assumption based on guessing, pattern matching from other codebases, or "usually works this way." No evidence. |
| **Medium** | Assumption based on partial evidence (saw similar code, documentation suggests it, but didn't verify for this specific case). |
| **Low** | Assumption based on direct evidence (read the source, tested at REPL, confirmed by user) but conditions could change. |

---

## Blast Radius

The same wrong assumption has different risk depending on where it occurs:

| Scope | Blast radius | Risk adjustment |
|-------|-------------|-----------------|
| Leaf function (called by 1 place) | Contained | No adjustment |
| Shared utility (called by 5+ places) | Wide | +1 level |
| System boundary (API, DB schema, config) | System-wide | +1 level |
| Data model / state shape | Everything downstream | +2 levels |

A wrong assumption about a leaf function might be LOW. The same wrong assumption about a shared data model is HIGH.

---

## Reversibility

How hard is it to undo if the assumption is wrong?

| Action | Reversibility | Risk adjustment |
|--------|--------------|-----------------|
| Adding new code | Easy (delete it) | No adjustment |
| Modifying existing code | Medium (git revert, but downstream effects) | No adjustment |
| Deleting code | Hard (need to reconstruct, may lose context) | +1 level |
| Schema/data migration | Very hard (data already transformed) | +2 levels |
| Published API change | Irreversible (clients depend on it) | +2 levels |

---

## Risk Level Definitions

Use these consistently in `## Risk Assessment` sections:

| Level | Meaning | Action |
|-------|---------|--------|
| **NONE** | Validated, no meaningful risk | Proceed |
| **LOW** | Validated, minor impact if wrong, easily reversible | Proceed |
| **MEDIUM** | Unvalidated, or validated but moderate impact | Validate before proceeding, or document why validation isn't feasible |
| **HIGH** | Unvalidated with high impact, or validated with high blast radius | STOP — escalate to user |
| **ACCEPTED** | User reviewed MEDIUM/HIGH risk and chose to proceed | Proceed (user owns the risk) |

---

## Writing Risk Assessment Sections

Format for each assumption in the plan:

```
- ASSUMPTION: [what the plan depends on]
  - STATUS: Validated / Unvalidated
  - RISK: NONE / LOW / MEDIUM / HIGH
  - EVIDENCE: [how it was validated, or why it couldn't be]
  - IMPACT IF WRONG: [what breaks]
  - BLAST RADIUS: [leaf / shared / system / data model]
```

End with:

```
Overall risk level: [highest individual risk across all assumptions]
```

The overall level is the **max** of all individual levels. One HIGH assumption makes the overall HIGH, regardless of how many are LOW.

---

## Core Rule: Risk Assessment Is Not a TODO List

A risk assessment resolves assumptions — it does not defer them. If the evidence field says "need to check X," "will verify during implementation," or "should grep before deleting," you haven't assessed the risk. You've written a TODO.

**Do the check now.** The purpose of derisking is to validate assumptions *during planning*, so you go into implementation with known risks, not unknown ones. If you can grep, grep now. If you can REPL, REPL now. If you need to ask the user, ask now.

```
BAD:
  - EVIDENCE: Need to grep before deleting       ← This is a TODO, not evidence

GOOD:
  - EVIDENCE: grep -r "icons" src/ returns only chat_panel.cljc references   ← This is evidence
```

If validation genuinely can't be done during planning (requires running the full system, needs production data, depends on external service), document **why** it can't be done — and the risk stays MEDIUM or higher.

---

## Anti-Patterns

**Wishful risk assessment:**
```
- ASSUMPTION: This API supports streaming
  - STATUS: Unvalidated
  - RISK: LOW          ← WRONG: unvalidated cannot be LOW
  - EVIDENCE: Need to check docs
```

**Validation theater:**
```
- ASSUMPTION: Deleting icons.cljc is safe
  - STATUS: Unvalidated
  - RISK: LOW          ← WRONG: deletion is irreversible, grep takes 2 seconds
  - EVIDENCE: Need to grep before deleting
```

**Correct version:**
```
- ASSUMPTION: icons.cljc is only used by chat_panel.cljc
  - STATUS: Validated
  - RISK: NONE
  - EVIDENCE: grep -r "icons" src/ returns only chat_panel.cljc references
```

---

## Summary

1. **Unvalidated ≠ LOW** — if you haven't checked, it's MEDIUM minimum
2. **Cheap validation = no excuse** — grep/REPL takes seconds, do it now
3. **Impact × likelihood** — standard matrix, calibrated for code changes
4. **Blast radius matters** — shared components amplify risk
5. **Reversibility matters** — deletions and schema changes are high risk
6. **Overall = max** — one HIGH makes the whole plan HIGH
7. **ACCEPTED is a user decision** — never self-assign it
