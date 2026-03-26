---
name: pdca-cycle
description: Plan-Do-Check-React cycle for complex work. Use when work spans multiple files, has 5+ task checkboxes, or involves architectural changes. Guides phase transitions, gap analysis, and lessons learned.
---

# PDCA Cycle

A loop for complex work: Plan → Do → Check → React → (repeat or done).

**Use PDCA when:**
- Plan has more than ~5 checkboxes
- Work touches more than ~3 files
- Architectural changes or multi-component features

**Skip PDCA for:** Quick bug fixes, typos, single-file changes. Use `-` as the phase.

---

## The Loop

```
┌──→ Plan ──→ Do ──→ Check ──→ React ──┐
│                                        │
│    (gaps found → back to Plan)         │
└────────────────────────────────────────┘
                   │
              (no gaps → done, pop stack)
```

This is a loop, not a linear sequence. It repeats until the work is complete with no remaining gaps.

---

## Phases

### Plan (`pdca:plan`)

Create or refine a GitHub issue with a task list. This is the plan of record.

**Requirements:**
1. Use Claude's plan mode to analyze the codebase
2. Exit plan mode to create/update the issue
3. Include a `## Core Assumptions` section — facts the plan depends on, each with a verification method (e.g., "verify at REPL", "confirm via grep")

**Issue body format** (problem first — see [documentation-maintenance](../documentation-maintenance/)):
```markdown
## Problem
[What's wrong or missing]

## Repro (if applicable)
[Minimal code or steps]

## Impact
[Who's affected]
```

Post the task list and implementation plan as the **first comment**, not in the body.

**Every PDCA issue must end with:**
```markdown
---
## PDCA Reminder
This issue follows the PDCA cycle. When all tasks above are complete:
1. Update the issue label from `pdca:do` → `pdca:check`
2. Update `.claude/issue-stack.md` phase from `do` → `check`
3. Enter plan mode
4. Review all changes against this plan and post a gap analysis as a comment
5. Evaluate all touched files for purity violations — present for user approval
6. Reflect on lessons learned during Do — save durable insights to auto-memory
7. Present the gap analysis to the user and transition to `react`
Do not close this issue or declare done until the full cycle completes.
```

### Do (`pdca:do`)

Execute the plan by dispatching sub-agents for each task. Update issue checkboxes and add comments as work completes.

**Halt-on-violated-assumptions:** Before or during each task, verify the core assumptions listed in the plan. If any assumption is wrong, **STOP immediately** — do not attempt workarounds. Post a comment explaining which assumption was violated and what was actually observed, then transition back to `pdca:plan`.

### Check (`pdca:check`)

After all Do-phase tasks are complete, **enter plan mode** and produce a gap analysis as a comment on the issue:

- Tasks completed vs tasks planned
- Deviations from the plan (intentional or accidental)
- New issues discovered during implementation
- Quality concerns (tests missing, edge cases unhandled)
- Purity violations in touched files — flag hidden state, impure functions, missing `!` suffixes
- Documentation updated for any user-visible features

**Lessons learned** — reflect on the Do phase. These are reusable insights, not issue-specific details:
- Planning heuristics that worked or failed
- Execution patterns worth repeating
- Pitfalls to avoid next time
- Process improvements

Save durable lessons to auto-memory. Post ephemeral observations in the issue comment only.

Plan mode is used intentionally — Check is read-only analysis.

### React (`pdca:react`)

Present the gap analysis to the user. **This is a decision point, not a planning activity.**

- **No gaps / all acceptable** → Done. Pop the issue from the stack.
- **Gaps need fixing** → Loop back to Plan. User indicates which gaps matter.
- **Defer gaps** → Create follow-up issues. Pop the current issue.

React never produces a plan — it decides *whether* to re-plan. Do not auto-resolve gaps — the user decides what matters.

---

## Phase Transitions

Always update in this order:
1. **GitHub issue label** — source of truth
2. **`.claude/issue-stack.md`** — local cache for hooks

```bash
gh issue edit #N --remove-label "pdca:do" --add-label "pdca:check"
```

---

## Integration with Plugin Hooks

The plugin provides automation hooks for PDCA transitions:

| Hook | Event | What it does |
|------|-------|-------------|
| `pdca-plan-on-enter-plan-mode.sh` | PreToolUse:EnterPlanMode | Transitions label to `pdca:plan` |
| `plan-principles-check.sh` | PreToolUse:ExitPlanMode | Validates plan principles |
| `decomplection-review.sh` | PreToolUse:ExitPlanMode | Gates exit with decomplection checklist |
| `derisk-on-exit-plan.sh` | PreToolUse:ExitPlanMode | Loops /derisk until all risks are LOW |
| PostToolUse:Task | PostToolUse:Task | Prompts Check phase when Do tasks complete |
| Stop | Stop | Checks PDCA phase and prompts next action |

---

## Related Skills

- [documentation-maintenance](../documentation-maintenance/) — issue authoring standards (problem first)
- [learning-capture](../learning-capture/) — where to persist lessons learned from Check phase
- [decomplection-first-design](../decomplection-first-design/) — decomplection review at plan exit
