---
name: pdca-routing
description: "Use when the user mentions PDCA, asks to work on or execute a GitHub issue, says 'pdca issue N', 'work on issue N', 'run pdca on N', or wants to start the plan-do-check-react cycle on an issue"
---

The user wants to run the PDCA cycle on a GitHub issue.

Invoke the `/pdca` command with the issue number. For example, if the user says "pdca issue 12", invoke `/pdca 12`.

If no issue number is mentioned, invoke `/pdca` with no arguments — it will read from the issue stack.
