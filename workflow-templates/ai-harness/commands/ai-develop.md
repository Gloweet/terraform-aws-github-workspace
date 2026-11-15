---
description: Develop a ticket into a pull request - resolve it, claim it on Linear, implement it, run the repo's gates, self-review, then push and open a PR.
agent: develop-coordinator
---

<invocation>
Carry the ticket reference(s) below to a pull request, in this order, one PR per
ticket.

With no reference, this is the unattended case: pick the highest-priority ticket
from the team's To-do column. An empty To-do column is a valid end state - write
the empty report and stop, do not pick from another column and do not invent
work. If Linear is unreachable, fall back to the GitHub issue path and say so.

Follow the `develop-ticket` skill (`.agents/skills/develop-ticket/SKILL.md`) end
to end and write the run summary to `.opencode/agent-summary.md`.
</invocation>

<ticket_references>
$ARGUMENTS
</ticket_references>
