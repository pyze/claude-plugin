---
name: documentation-maintenance
description: Follow documentation placement and maintenance guidelines. Use when creating docs, updating memories, or deciding where documentation belongs.
---

# Documentation Maintenance Skill

How to keep documentation accurate, complete, and in the right place.

## Skill Boundary

This skill covers: **Where to put documentation** - placement decisions, memories vs CLAUDE.md vs skills.

**Use DIFFERENT skill if:**
- Whether/how to write specs → [specification-first-development](../specification-first-development/)

## When to Use This Skill

**Invoke this skill when**:
- Creating new documentation
- Deciding where information belongs
- Recording a discovery or insight
- Updating existing documentation
- Reviewing documentation quality

## Quick Decision: Where Does It Go?

| Location | Purpose | Condition |
|----------|---------|-----------|
| **CLAUDE.md** | High-signal project guidance | Specific to THIS project, referenced frequently |
| **docs/** | Implementation details | Setup, commands, procedures, configuration |
| **.claude/skills/** | Reusable patterns | Techniques applicable across projects |
| **memories/** | Discoveries & insights | Non-obvious patterns, bug root causes |

### CLAUDE.md (Project Guidance)

**Use for**:
- Critical safety notes (port conventions, naming)
- Core project methodology (workflows)
- Project-specific architecture patterns
- Explicit "do not do this" warnings

**Examples**:
- "Integrant services use slash notation, not hyphens"
- "Use :http/post-edn! for EDN communication"
- "Fail-fast philosophy prevents production bugs"

### .claude/skills/ (Reusable Patterns)

**Use for**:
- Implementation patterns with examples
- Debugging methodologies
- Tool usage and best practices
- Deep dives into specific technologies

**Condition**: Pattern is useful enough to promote beyond this project.

### memories/ (Discoveries & Insights)

Discoveries and insights go to `memories/` using your project's memory system.

## Documentation Standards

Keep docs accurate and complete. For learning persistence decisions, see [learning-capture](../learning-capture/).

## Issue Authoring

**Issue body = problem, not solution.**

The issue body describes *what's wrong*. Solution ideas, feature requests, and implementation plans go in **comments** after the issue is created.

| Content | Issue body | Comments |
|---------|:---:|:---:|
| Problem statement | ✅ | |
| Minimal repro case | ✅ | |
| Impact (who, how often, severity) | ✅ | |
| Solution ideas | | ✅ |
| Feature requests | | ✅ |
| Implementation plans / task lists | | ✅ |

**Why:** Separating problem from solution prevents anchoring on a particular approach before the problem is fully understood. Solutions can evolve in comments without rewriting the issue.

**Template:**
```markdown
## Problem
[Observable behavior vs expected behavior]

## Repro (if applicable)
[Minimal code, steps, or failing test]

## Impact
[Who's affected, how often, severity]
```

---

## Templates

### New Skill

```markdown
---
name: skill-name
description: One-line description
---

# Skill Name

Brief intro sentence.

## When to Use This Skill

**Invoke when**:
- Use case 1
- Use case 2

## Core Concept

What to understand first.

## [Main Sections]

Content with examples.

## Summary

Key takeaways.
```

## Summary

1. **CLAUDE.md**: Project-specific, high-signal guidance
2. **docs/**: Implementation details, setup, procedures
3. **skills/**: Reusable patterns across projects
4. **memories/**: Discoveries and insights
5. **Update after bugs**: Improve documentation that led to issues
6. **Get approval**: Before removing documentation
7. **Use checklist**: Verify correctness, clarity, completeness before committing
