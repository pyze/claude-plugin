---
name: tool-selection
description: "Choose the right tool for code navigation, search, and validation. Use when deciding between LSP, REPL, grep, and glob — prefer semantic tools over text matching."
---

# Tool Selection Skill

Use the most semantically accurate tool for the task. Text search is a fallback, not a default.

## Tool Preference Hierarchy

```
LSP > REPL > Grep/Glob
```

- **LSP** understands code structure — symbols, references, namespaces, aliases
- **REPL** understands runtime behavior — data shapes, return values, live state
- **Grep** understands text — literal string matching, no semantic awareness

Default to the highest-fidelity tool available. Drop to a lower tool only when the higher one can't answer the question.

---

## When to Use Each Tool

### LSP (clojure-lsp / cclsp)

Use for anything about **code structure and relationships**:

| Task | LSP method |
|------|-----------|
| Find all usages of a function | `find_references` |
| Find all usages of a namespace | `find_references` on the ns symbol |
| Is this code dead? | `find_references` — 0 results = dead |
| Where is this defined? | `goto_definition` |
| Rename a symbol safely | `rename` |
| What does this namespace export? | `document_symbols` |

**Why not grep?** Grep finds text, not references. It misses aliased requires (`[my.ns :as m]` — grep for `my.ns` won't find `m/fn`), catches false positives in comments and strings, and doesn't understand Clojure's namespace resolution.

### REPL (clojure_eval / clojure-mcp)

Use for anything about **runtime behavior and data**:

| Task | REPL approach |
|------|--------------|
| What shape does this function return? | Call it and inspect |
| Does this API support X? | Try it |
| What's the current system state? | Query it |
| Does this config key exist? | Look it up |
| Validate an assumption | Execute and verify |
| Explore unfamiliar code | Load namespace, call functions, inspect results |

**Why not grep?** Grep can find where a function is defined, but can't tell you what it returns. Only the REPL gives you actual runtime data.

### Grep / Glob

Use for **text patterns and file discovery**:

| Task | Tool |
|------|------|
| Find files matching a name pattern | Glob |
| Find a specific string literal | Grep |
| Count occurrences of a pattern | Grep |
| Find TODO/FIXME/HACK comments | Grep |
| Search across non-Clojure files (config, docs, scripts) | Grep |

**When grep is the right tool:** When the question is about text, not code. "Where does this error message appear?" is a grep question. "What calls this function?" is an LSP question.

---

## Common Mistakes

### Using grep for reference finding

```
BAD:  grep -r "icons" src/     ← finds text matches, not references
GOOD: LSP find_references       ← finds actual code references
```

Grep for "icons" will match comments, strings, similar names (`my-icons`, `icons-v2`), and miss aliased references.

### Using grep for "is this dead code?"

```
BAD:  grep -r "my-function" src/ | wc -l   ← counts text matches
GOOD: LSP find_references on my-function    ← counts actual callers
```

### Using grep when REPL would be faster

```
BAD:  grep through source to understand what a function returns
GOOD: (my-fn test-input)  ← see the actual return value
```

### Defaulting to grep because it's familiar

Grep is always available and always works. That makes it the easy choice (in Hickey's sense — nearby, familiar). But LSP and REPL are the simple choice — they give you the right answer with less interleaving of irrelevant results.

---

## Decision Tree

```
What are you trying to find out?
│
├─ Code relationships (who calls X, where is X defined, is X dead?)
│   └─ Use LSP
│
├─ Runtime behavior (what does X return, does X work, what's the current state?)
│   └─ Use REPL
│
├─ Text patterns (literal strings, comments, non-code files?)
│   └─ Use Grep/Glob
│
└─ Not sure?
    └─ Try LSP first, REPL second, grep last
```

---

## Summary

1. **LSP for structure** — references, definitions, renames, dead code detection
2. **REPL for behavior** — data shapes, validation, exploration, live state
3. **Grep for text** — literal patterns, non-code files, counting occurrences
4. **Never grep for references** — use LSP; grep misses aliases and catches false positives
5. **Familiar ≠ correct** — grep is easy (nearby), LSP is simple (right answer)
