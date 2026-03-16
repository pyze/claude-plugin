# /execute

Execute an implementation plan from a GitHub issue.

Takes a GitHub issue number as `$ARGUMENTS` (bare integer or `#`-prefixed). If no argument, reads the top of `.claude/issue-stack.md`.

## Workflow

1. **Parse issue number** from `$ARGUMENTS` (strip `#` if present)
2. **Read the issue** via `gh issue view <number>` or GitHub MCP (`issue_read` method `get`)
3. **Read issue comments** for amendments or additional context (`get_comments`)
4. **Push onto stack** if not already in `.claude/issue-stack.md` — set phase to `do`
5. **Set PDCA label** to `pdca:do` on the issue if not already set
6. **Invoke `superpowers:executing-plans`** with the issue body as the plan — follow it exactly for task-by-task execution with review checkpoints
