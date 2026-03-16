# /five-whys — Root Cause Analysis for Claude Mistakes

When Claude makes a mistake, performs a shoddy investigation, or reaches a wrong conclusion, use this command to systematically trace why it went astray and propose documentation improvements that prevent recurrence.

**Core insight**: Claude mistakes are rarely random — they follow from gaps, ambiguities, or misleading patterns in the documentation Claude reads. Fix the documentation, fix the behavior.

## How It Works

### Step 1: Identify the Mistake

State clearly and specifically what went wrong:

```
MISTAKE: [What Claude did or concluded incorrectly]
CORRECT: [What should have happened instead]
IMPACT:  [Time wasted, wrong code written, user frustration, etc.]
```

If the user provides `$ARGUMENTS`, use that as context for identifying the mistake. Otherwise, review the conversation history for the most recent mistake or shoddy investigation.

### Step 2: Apply the Five Whys

Starting from the mistake, ask "Why?" repeatedly until you reach a root cause that is actionable through documentation changes.

```
WHY 1: Why did Claude [make the mistake]?
  → Because [immediate reason]

WHY 2: Why did [immediate reason] happen?
  → Because [deeper reason]

WHY 3: Why did [deeper reason] happen?
  → Because [even deeper reason]

WHY 4: Why did [even deeper reason] happen?
  → Because [structural/documentation gap]

WHY 5: Why did [structural/documentation gap] exist?
  → Because [root cause — addressable via documentation]
```

**Rules for good Whys:**
- Each "Why" must be factual, not speculative
- Reference specific decisions, code reads, or assumptions Claude made
- Stop when you reach something fixable in Claude-facing documentation
- You may need fewer than 5 Whys — stop when you hit the root cause
- You may need more than 5 — keep going if needed

### Step 3: Categorize the Root Cause

Classify the root cause into one or more categories:

| Category | Description | Fix Target |
|----------|-------------|------------|
| **Missing guidance** | No documentation covers this scenario | New skill section or CLAUDE.md addition |
| **Misleading guidance** | Documentation suggests the wrong approach | Edit existing docs to clarify |
| **Stale documentation** | Docs describe old behavior/architecture | Update to match current code |
| **Missing constraint** | No rule prevents the bad behavior | Add explicit constraint/red-flag |
| **Missing discovery pattern** | No documented way to find the right info | Add discovery command to NAVIGATION.md |
| **Cognitive shortcut** | Claude took a plausible but wrong shortcut | Add anti-pattern warning |
| **Insufficient examples** | Docs lack examples of the correct approach | Add concrete examples |
| **Wrong mental model** | Docs frame the concept in a misleading way | Rewrite framing |

### Step 4: Propose Improvements

For each root cause, propose a specific, concrete documentation change:

```
FILE:    [exact path]
SECTION: [section name or line range]
CHANGE:  [add/edit/remove]
CONTENT: [exact text to add or modify]
RATIONALE: [why this prevents the mistake]
```

**Prioritize by impact:**
1. CLAUDE.md changes (loaded every session)
2. MEMORY.md changes (loaded every session)
3. Skill SKILL.md changes (loaded when relevant)
4. NAVIGATION.md changes (affects discovery)
5. New skills or commands (last resort — prefer editing existing docs)

### Step 5: Present to User

Present findings as:

```
## Five Whys Analysis

### The Mistake
[Clear statement]

### Why Chain
1. [Why 1]
2. [Why 2]
...

### Root Cause Category
[Category from table above]

### Proposed Improvements
[Numbered list of specific file changes]

### Expected Impact
[How this prevents recurrence — be specific]
```

### Step 6: Implement (with user approval)

After presenting the analysis, ask the user:

```
Should I implement these documentation improvements?
1. Yes, implement all
2. Let me pick which ones
3. No, just noting for now
```

If approved, make the changes using Edit/Write tools.

## Anti-Patterns

**Don't do these:**

| Anti-Pattern | Why It's Bad | Do This Instead |
|--------------|-------------|-----------------|
| "Claude should have been smarter" | Not actionable | Find the documentation gap |
| Blame the model's capabilities | Can't fix that | Fix the instructions the model reads |
| Propose vague improvements | "Add more detail" doesn't help | Write the exact text to add |
| Create a new skill for everything | Skill proliferation | Prefer editing existing docs |
| Propose changes that only help this exact case | Too narrow | Generalize the improvement |
| Skip the why chain | Miss the root cause | Follow the full chain |

## Example

```
MISTAKE: Claude concluded that Pyramid can't normalize map-valued idents,
         but the project uses a custom viz-ident function that handles them.

WHY 1: Why did Claude conclude Pyramid can't normalize map-valued idents?
  → Because REPL testing with plain `{}` db confirmed map idents don't normalize.

WHY 2: Why did Claude test with plain `{}` instead of `(store/initial-db)`?
  → Because the debugging approach tested the library in isolation,
    not with the project's actual configuration.

WHY 3: Why didn't Claude test with the project's actual configuration?
  → Because no documentation reminds Claude that Pyramid uses a custom
    ident function (viz-ident) that changes normalization behavior.

WHY 4: Why isn't the custom ident function documented prominently?
  → Because MEMORY.md and skills don't mention that `store/initial-db`
    uses `viz-ident` with `ident/by-keys` for extended key recognition.

ROOT CAUSE: Missing guidance — no documentation warns that testing Pyramid
with plain `{}` gives different results than the project's configured db.

PROPOSED FIX:
FILE:    .claude/projects/.../memory/MEMORY.md
SECTION: "Data Pipeline Casing" (or new "Pyramid Configuration" section)
CHANGE:  add
CONTENT: |
  ## Pyramid Configuration
  - `store/initial-db` uses custom `viz-ident` (via `ident/by-keys`) that
    recognizes entity keys including `:pivot/query`, `:data/id`, etc.
  - ALWAYS test Pyramid behavior with `(store/initial-db)`, NOT plain `{}`.
    Plain `{}` uses default ident function which has different normalization.
```

## When to Use

- After Claude reaches a wrong conclusion during debugging
- After Claude writes code based on incorrect assumptions
- After Claude wastes time investigating a dead-end
- When a skill or doc failed to prevent a known mistake
- When the user says "that's wrong" or "you missed X"
- After any investigation that the user considers "shoddy"
