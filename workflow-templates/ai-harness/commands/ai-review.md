---
description: Review a PR with the AI review coordinator - fan out to the specialist subagents, then post one consolidated review and an approve / comment / request-changes decision.
agent: review-coordinator
---

<invocation>
Follow the `review-pr` skill (`.agents/skills/review-pr/SKILL.md`) on the pull
request below.

Resolve it first (`gh pr view`), read the diff (`gh pr diff`), then fan out to
the `review-*` specialists whose trigger matches the changed files. Consolidate
their findings under the contract in `.agents/AGENT-MANIFEST.md` and post ONE
review on the PR (`gh pr review`) with the decision those findings justify.

You are read-only on code: never edit the branch, never push. If a finding is a
false positive, say why in one line instead of dropping it silently. An empty
finding list is a valid review - say so in one line and approve.
</invocation>

<pr_reference>
$ARGUMENTS
</pr_reference>
