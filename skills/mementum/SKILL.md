---
name: mementum
description: Git-based memory system for persistent learning. Use at session start to load context, when learning occurs to store it, and when encountering errors to search for solutions.
---

# Mementum: Git-Based Memory System

## Core Principle

```
store(x) when effort(x) > 1-attempt AND likely-recur(x)
```

Store when effort exceeds one attempt AND likely to recur.

## Symbol Vocabulary

| Symbol | Category | When to Use |
|--------|----------|-------------|
| insight | Novel discovery about a system/API/pattern |
| pattern | Behavioral pattern or anti-pattern identified |
| decision | Architectural/design decision with rationale |
| meta | Learning about how to learn/work effectively |

## Memory Format

**Constraint:** <=200 tokens total

```markdown
## Pattern
{One-sentence description of what was learned}

## Example
{Concrete code/command/scenario}

## Context
{When this applies, prerequisites, constraints}
```

## Operations

### Create Memory

```bash
# Using the CLI script (requires Babashka)
${CLAUDE_PLUGIN_ROOT}/skills/mementum/scripts/mementum.clj create SYMBOL "kebab-case-slug" "content"
```

Or manually:
```bash
# File: memories/YYYY-MM-DD-{slug}-{symbol}.md
echo "## Pattern
Description here

## Example
Code/scenario here

## Context
When this applies" > memories/$(date +%Y-%m-%d)-my-slug-insight.md
git add memories/ && git commit -m "insight: my-slug"
```

### Recall Memories

**Fibonacci-weighted temporal search:**
```bash
# Recent (depth 2 = 3 entries)
git log -n 3 --pretty=format:"%s" -- memories/

# Deeper (depth 3 = 5 entries, depth 4 = 8 entries)
${CLAUDE_PLUGIN_ROOT}/skills/mementum/scripts/mementum.clj recall "" 4
```

**Semantic search:**
```bash
git grep -i "query" memories/
```

**Combined (recommended):**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/mementum/scripts/mementum.clj recall "query" 3
```

### List Memories

```bash
${CLAUDE_PLUGIN_ROOT}/skills/mementum/scripts/mementum.clj list 10
# Or: ls -t memories/*.md | head -10
```

## Auto-Trigger Conditions

### When to Store

| Signal | Threshold | Action |
|--------|-----------|--------|
| Multiple attempts | attempts > 1 | Consider storing |
| Extensive tool use | tool_calls > 3 | Consider storing |
| User correction | any | Store the correction |
| Novel solution | domain-specific | Store as insight |
| Architecture decision | >1 week impact | Store as decision |
| Error pattern | debugging cost > 10min | Store as pattern |

### When to Recall

| Context | Action |
|---------|--------|
| Session start | Load recent 3 memories |
| Error encountered | Search for similar patterns |
| New domain entered | Search domain-specific memories |
| Before architectural decision | Search for decision memories |

## OODA Loop Integration

```
observe(error|difficulty|learning)
  -> recall(memory)
  -> decide(apply|debug)
  -> act
  -> store-if-new
```

## Skip Criteria

Do NOT store:
- Routine changes
- Incremental work
- Minor fixes
- Already documented patterns
- One-off solutions unlikely to recur

## Session Workflow

### Session Start
```bash
# Load recent context
git log -n 3 --pretty=format:"- %s: %b" -- memories/ 2>/dev/null || echo "No memories yet"
```

### During Session
- When learning detected: Create memory with appropriate symbol
- When error encountered: Search memories first

### Session End
- Review if any learning moments occurred
- Store valuable learnings before ending

## File Structure

```
memories/
  README.md
  2026-01-28-some-pattern.md
  2026-01-28-some-insight.md
  ...
```

## Validation Rules

1. **Token limit:** Content must be <=200 tokens
2. **Slug format:** kebab-case only (`[a-z0-9-]+`)
3. **Date auto-generated:** YYYY-MM-DD format

## Integration with Other Skills

- **systematic-debugging:** Store root cause findings as patterns
- **repl-driven-development:** Store REPL discoveries as insights
- **specification-first-development:** Store spec decisions as decisions
