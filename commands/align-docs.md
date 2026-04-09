---
name: align-docs
description: Proactive documentation audit for ambiguities and conflicts
---

# /align-docs — Align Claude-Facing Documentation

Proactively audit all Claude-facing documents for ambiguities, redundancies, conflicts, and staleness. Produces a prioritized report, then walks through each finding one-by-one with proposed fixes.

**Core insight**: Documentation drift is inevitable in a project with ~45 Claude-facing files. `/five-whys` fixes mistakes reactively; `/align-docs` prevents them proactively by keeping the documentation surface internally consistent.

## When to Use

- Periodically (e.g., after a batch of features or major refactors)
- When Claude makes mistakes that suggest stale or contradictory guidance
- After adding or substantially editing skills, memory files, or CLAUDE.md sections
- Before onboarding a new team member or AI agent to the project

## How It Works

### Phase 1: Discovery (4 Parallel Agents)

Launch 4 Explore agents in a single message. Each agent reads the full document set but focuses on one analysis dimension.

**Document set** (all Claude-facing files):
- `CLAUDE.md` (project root)
- `.claude/skills/NAVIGATION.md`
- `.claude/skills/*/SKILL.md` and sub-files (all skills)
- `.claude/commands/*.md` (all commands)
- Auto-memory files (`MEMORY.md` index + all referenced `.md` files in the memory directory)
- `.claude/agents/*.md`

#### Agent 1: Redundancy

> Read all Claude-facing documents listed above. For each concept, rule, or pattern, track every location where it appears. Cross-reference against `.claude/skills/NAVIGATION.md`'s "Canonical Sources of Truth" table.
>
> Report findings in this format:
> ```
> ## Redundancy Findings
>
> ### R1: [Concept name]
> - **Locations:**
>   - file1.md:section — "quoted key text"
>   - file2.md:section — "quoted key text"
> - **Canonical source (per NAVIGATION.md):** [skill name] or "NOT LISTED"
> - **Divergence:** [how the versions differ, if at all]
> - **Recommendation:** [consolidate to canonical / add to canonical table / remove duplicate]
> ```
>
> Focus on:
> - Concepts in 2+ places where content diverges (even slightly different wording)
> - Concepts missing from the canonical sources table entirely
> - Memory operational notes that duplicate skill content verbatim
> - CLAUDE.md sections that repeat what a skill already covers in detail

#### Agent 2: Conflicts

> Read all Claude-facing documents listed above. Look for contradictions — places where two documents give incompatible guidance for the same situation.
>
> Report findings in this format:
> ```
> ## Conflict Findings
>
> ### C1: [Short description of conflict]
> - **Source A:** file1.md:section — "quoted guidance"
> - **Source B:** file2.md:section — "quoted contradictory guidance"
> - **Nature:** [direct contradiction / implicit tension / scope ambiguity]
> - **Recommendation:** [which source should win and why]
> ```
>
> Specific checks:
> - Rules in CLAUDE.md that conflict with skill SKILL.md guidance
> - Memory operational notes that contradict current skill content
> - Commands that describe processes differently than CLAUDE.md
> - PDCA/planning/execution guidance that's inconsistent across sections
> - Auto-start policy vs plan-mode restrictions
> - Testing guidance that differs between testing-patterns skill and CLAUDE.md

#### Agent 3: Staleness

> Read all Claude-facing documents listed above. For each factual claim (function names, namespace paths, file paths, issue numbers, architecture descriptions), verify it against the current codebase using Grep and Glob.
>
> Report findings in this format:
> ```
> ## Staleness Findings
>
> ### S1: [What's stale]
> - **Location:** file.md:section — "quoted stale text"
> - **Verification:** [grep/glob command and result showing it's stale]
> - **Current reality:** [what the code actually looks like now]
> - **Recommendation:** [update text / remove reference / mark as historical]
> ```
>
> Specific checks:
> - Function/namespace references — grep for them in src/, flag if missing
> - File path references — glob for them, flag if missing
> - Issue number references — check if contextually outdated
> - "Active Context" sections in memory referencing old branches
> - Architecture descriptions that don't match current code structure
> - Render pipeline descriptions (has changed significantly across #453/#463)

#### Agent 4: Memory Promotion

> Read all auto-memory files (MEMORY.md index + each referenced .md file). For each memory, evaluate whether it should be promoted to a skill or CLAUDE.md.
>
> Report findings in this format:
> ```
> ## Memory Promotion Findings
>
> ### P1: [Memory file name]
> - **Content:** "quoted key insight"
> - **Current location:** memory/[file].md
> - **Promotion target:** [skill name]/SKILL.md or CLAUDE.md:[section]
> - **Reason:** [duplicates skill content / pattern validated across sessions / project-wide guidance]
> - **Action:** [absorb into skill and delete memory / merge into CLAUDE.md / keep as memory]
> ```
>
> Promotion criteria:
> - **Promote to skill** if the memory describes a reusable pattern, coding guideline, or design principle that applies across projects. Check if a skill already covers this — if so, the memory is redundant and should be deleted.
> - **Promote to CLAUDE.md** if the memory describes a project-specific convention, workflow preference, or configuration that applies to the current project but not others.
> - **Keep as memory** if the memory is about the user (preferences, role), is time-bound (project status), or is a reference pointer (external system locations).
> - **Delete** if the memory duplicates a skill verbatim or has become stale (references removed features, closed issues, or outdated patterns).

### Phase 2: Merge & Prioritize

After all 3 agents complete, merge their findings:

1. **Deduplicate** — if multiple agents flagged the same location, merge into one finding
2. **Classify severity**:
   | Category | Severity | Rationale |
   |----------|----------|-----------|
   | Conflict | High | Contradictory guidance causes wrong behavior |
   | Staleness | High | Dead references waste investigation time |
   | Memory duplicate | High | Memory duplicating skill content causes drift |
   | Redundancy | Medium | Drift risk, but not immediately harmful |
   | Ambiguity | Medium | May cause wrong interpretation |
   | Memory promotion | Medium | Validated pattern stuck in memory instead of skill |
   | Missing canonical | Low | Organizational improvement |

3. **Sort** — high severity first, then by number of files affected (more = higher priority)

4. **Present summary** — before walking through individual findings, show:
   ```
   ## Alignment Report Summary

   Found N findings across M files:
   - X conflicts (high)
   - Y stale references (high)
   - Z memory duplicates (high)
   - W redundancies (medium)
   - V memory promotions (medium)
   - U ambiguities (medium)
   - T missing canonicals (low)

   Ready to walk through each finding. [Proceed] [Show report only]
   ```

### Phase 3: Interactive Walk-Through

For each finding, present and wait for user decision:

```
## Finding N/M: [Category] — [Short title]

**Location(s):**
- file1.md:L42 — "quoted text"
- file2.md:L87 — "quoted text"

**Issue:** [1-2 sentence explanation of what's wrong and why it matters]

**Proposed fix:**
- **File:** [path]
- **Action:** [edit / remove / add]
- **Old text:** [exact text to replace, if editing]
- **New text:** [replacement text]
- **Rationale:** [why this fix is correct]
```

Then ask the user via AskUserQuestion with options:
- **Apply** — make the proposed edit
- **Skip** — move to next finding
- **Modify** — user provides alternative fix text

If the user chooses "Apply", use the Edit tool to make the change immediately, then proceed to the next finding.

After all findings are processed, show a summary:
```
## Alignment Complete

- Applied: N fixes
- Skipped: M findings
- Modified: P fixes

Files changed:
- [list of modified files]
```

## Finding Quality Standards

**Good finding:**
- Quotes exact text from both sources
- Explains WHY it's a problem (not just that text differs)
- Proposes a specific, minimal fix
- Identifies which source is authoritative (per NAVIGATION.md)

**Bad finding (skip these):**
- Cosmetic wording differences with identical meaning
- Different levels of detail that don't contradict
- Intentional cross-references (skill A linking to skill B is fine)
- Historical context in memory that's clearly labeled as such

## Related Commands

- `/five-whys` — Reactive root cause analysis for specific Claude mistakes
- `/code-cleanup` — Static analysis of Clojure code (not documentation)

## Related Skills

- `documentation-maintenance` — Placement and maintenance guidelines
- Project memory system — for discoveries and insights
