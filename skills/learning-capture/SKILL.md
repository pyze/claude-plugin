---
name: learning-capture
description: Decide when and where to persist learnings. Use after completing tasks, receiving user corrections, or discovering non-obvious patterns — to choose between auto-memory, skill updates, or CLAUDE.md changes.
---

# Learning Capture

Decide whether a learning is worth persisting, and where it should go.

**This skill covers:** The decision of *when* and *where* to save learnings.

**Use DIFFERENT skill if:**
- Auto-memory mechanics (file format, MEMORY.md index) → built-in auto-memory instructions
- Updating skills or CLAUDE.md → [documentation-maintenance](../documentation-maintenance/)

---

## When to Save

```
store(x) when effort(x) > 1-attempt AND likely-recur(x)
```

| Signal | Threshold | Action |
|--------|-----------|--------|
| Multiple attempts to solve | attempts > 1 | Save the solution |
| User correction | any | Save as auto-memory `feedback` |
| Novel discovery about system/API | domain-specific | Save as auto-memory |
| Architecture decision | >1 week impact | Save as auto-memory `project` |
| Error pattern | debugging cost >10min | Save as auto-memory `feedback` |
| Extensive tool use for one question | tool_calls > 3 | Consider saving |

**Skip:** routine changes, incremental work, minor fixes, already-documented patterns, one-off solutions unlikely to recur.

---

## Where to Save

| What was learned | Where to persist | Why |
|-----------------|-----------------|-----|
| User corrected my approach | Auto-memory `feedback` | Stays with user across projects |
| User preference or role info | Auto-memory `user` | Tailors future interactions |
| Architectural/design decision | Auto-memory `project` | Context for this project's work |
| External resource location | Auto-memory `reference` | Pointer to where info lives |
| Project-specific rule | Project CLAUDE.md | Loaded for every session in this project |
| Reusable pattern across projects | Update a plugin skill | Available in all projects using the plugin |

**Heuristic:** If the learning is project-specific, it stays in auto-memory or CLAUDE.md. If it applies to any Clojure project, it belongs in a plugin skill.

---

## Decision Tree

```
Did I learn something non-obvious?
    │
    ├─ NO → Don't save
    │
    └─ YES → Will it recur?
              │
              ├─ NO → Don't save
              │
              └─ YES → Is it project-specific?
                        │
                        ├─ YES → Is it a rule Claude should always follow here?
                        │         │
                        │         ├─ YES → Add to project CLAUDE.md
                        │         │
                        │         └─ NO → Auto-memory (project/reference)
                        │
                        └─ NO → Does it apply to all Clojure projects?
                                  │
                                  ├─ YES → Update a plugin skill
                                  │
                                  └─ NO → Auto-memory (feedback/user)
```

---

## Integration with Other Skills

- **After /five-whys** — root cause findings often warrant a skill update or CLAUDE.md change
- **After /code-cleanup** — recurring violations suggest the relevant skill needs strengthening
- **During PDCA Check phase** — the gap analysis may reveal learnings worth persisting
