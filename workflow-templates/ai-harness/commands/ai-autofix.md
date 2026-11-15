---
description: Address the review comments on an existing PR in a separate context - fix what is reported, run the repo's gates, then push to the same branch.
agent: develop-coordinator
---

<invocation>
Read the review comments on the pull request below FRESH with `gh` (do not assume
anything about the reviewer's reasoning), fix every `critical` and `warning`
finding that is still valid on the current head, re-run the repo's gates, and
push to the same branch.

Do not re-review the PR and do not open a new one. If a comment is already
addressed on the current head, say so in one line instead of changing code for
it. Leave the ticket in the state you found it in unless a fix changes it.

Take the mechanics - branch handling, the gates, commit conventions, the summary
file - from the `develop-ticket` skill
(`.agents/skills/develop-ticket/SKILL.md`), but skip its resolve, claim and ship
steps: the ticket and the PR already exist.
</invocation>

<run_arguments>
$ARGUMENTS
</run_arguments>
