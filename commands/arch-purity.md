---
name: arch-purity
description: "Architectural gap analysis: validate code against declared architecture"
---

# /arch-purity

Validate code against a declared architecture document. Two modes:

## Mode 1: Architecture Interview (no `.claude/architecture.md` exists)

If `.claude/architecture.md` does not exist in the project, conduct an architecture interview:

1. **Read the codebase** — explore source, config, tests, and any existing documentation (CLAUDE.md, AGENTS.md)
2. **Ask about vision** — "Is this codebase where you want to be, or where you started from? What's your vision for where this project is going?"
3. **Walk through layers top-down**, one at a time. At each layer, propose 2-4 rules with prose explanations. Ask the user to confirm before moving to the next layer.

### Layers (adapted from VSM)

#### S5 — Identity (core invariants)
What principles won't you compromise on? What does failure of purpose look like?
- Format: `INVARIANT: [plain English rule that an agent can verify]`

#### S3 — Control (policies and constraints)
What resources need managing? What policies enforce the identity principles?
- Format: `POLICY: [enforceable rule with concrete threshold]`

#### S2 — Coordination (inter-module protocols)
How do subsystems work together? How does data flow? Where are the boundaries?
- Format: `PROTOCOL: [rule governing inter-module interaction]`

#### S1 — Operations (technology and tooling)
What tools, technologies, and concrete recipes?
- Format: `TOOL: [technology choice]` or `RECIPE: [concrete workflow]`

4. **At each layer, surface what's absent** — "What's missing? For each rule, what companion should exist alongside it?"
5. **Write the architecture document** to `.claude/architecture.md` in the project repo

### Architecture document format

```markdown
# {Project} — Architecture

## S5 — Identity (core invariants)
{prose context}
- INVARIANT: ...

## S3 — Control (policies and constraints)
{prose context}
- POLICY: ...

## S2 — Coordination (inter-module protocols)
{prose context}
- PROTOCOL: ...

## S1 — Operations (technology and tooling)
{prose context}
- TOOL: ...
- RECIPE: ...
```

## Mode 2: Gap Analysis (`.claude/architecture.md` exists)

If the architecture document exists, run the gap analysis:

### Step 1: Read the architecture document

Read `.claude/architecture.md` and extract all rules (INVARIANT, POLICY, PROTOCOL, TOOL, RECIPE).

### Step 2: Dispatch analysis agents in parallel

Launch one agent per analysis dimension. **Critical: each agent receives ONLY the architecture document and a focused question. No conversation history. No recent coding context.** This prevents rationalization bias — agents must evaluate what IS, not justify what they've seen.

Each agent has access to: Read, Grep, Glob, Bash (read-only), LSP.

#### Structural agents (require multi-module understanding)

| Agent | Focus | What to check |
|-------|-------|--------------|
| Dependency direction | `ns` require graph | Do requires flow inward per layer rules? Does any layer bypass its neighbor? |
| Layer violations | Cross-layer calls | Are there direct calls between non-adjacent layers? |
| State ownership | Atoms, refs, agents | Does each piece of mutable state have exactly one owning layer? |
| Side effect boundaries | Pure core / impure shell | Are side effects confined to designated boundary layers? |
| Data flow | Inter-module data movement | Does data flow through layers in the declared direction? |
| Error propagation | Exception handling across layers | Do domain errors leak infrastructure details? |
| Configuration | Config resolution | Is config resolved at boundaries or does it leak across layers? |
| Integrant graph | System component dependencies | Do component dependencies respect layer boundaries? |
| Protocol placement | Protocol definitions | Are protocols defined in the layer that needs the abstraction? |

#### Boundary agents (structural questions about specific concerns)

| Agent | Focus | What to check |
|-------|-------|--------------|
| Security boundaries | Auth/authz placement | Is authentication/authorization enforced at the correct architectural boundary? |
| Resiliency boundaries | Retry/circuit-breaker placement | Are failure handling mechanisms at the right layer? |
| Observability boundaries | Logging/tracing placement | Is logging at architectural boundaries, not scattered within layers? |

### Step 3: Merge and rank findings

Collect findings from all agents. For each finding:

1. **Classify severity by layer** — higher-layer violations are more severe:
   - S5 INVARIANT violation → **VIOLATION** (must fix)
   - S3 POLICY violation → **VIOLATION** or **WARNING**
   - S2 PROTOCOL violation → **WARNING**
   - S1 TOOL/RECIPE divergence → **NOTE**

2. **Deduplicate** — multiple agents may flag the same issue from different angles
3. **Add file:line references** and suggested fix direction

### Step 4: Present findings

Present the gap analysis to the user, organized by severity:

```
## VIOLATIONS (n found)
- [S5] INVARIANT: "Errors are signals" — but src/handler.clj:42 swallows exception in catch block
  Fix: Rethrow or log with Telemere, don't return nil

## WARNINGS (n found)
- [S3] POLICY: "No direct DB access from handlers" — but src/api/users.clj:18 calls db/query directly
  Fix: Route through service layer

## NOTES (n found)
- [S1] TOOL: Architecture says Redis for caching, but src/cache.clj uses in-memory atom
  Fix: Migrate to Redis or update architecture doc
```

### Step 5: Optionally post to GitHub issue

Ask the user: "Post findings to a GitHub issue for tracking?"

## Usage

```bash
# First run — interview and create architecture doc
/arch-purity

# Subsequent runs — gap analysis
/arch-purity

# Focus on specific dimension
/arch-purity dependency-direction

# Against specific files/directories
/arch-purity src/api/
```

Use `$ARGUMENTS` for optional focus area or file paths.
