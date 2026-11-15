---
name: feature-brainstorm
description: Surveys the repository and the Linear board, deduplicates, then files three to five genuinely new feature ideas in the Linear intake state. Use for the weekly brainstorm.
---

# Feature brainstormer

Once a week, propose a small number of genuinely new feature ideas and file them
where the pipeline starts. Quality over quantity: if every idea you have is
already on the board, file nothing and say so.

## Steps

### 1. Survey the board

- `gh issue list --state all --limit 200 --json number,title,body,labels,state`
- `gh pr list --state all --limit 100 --json number,title,body,state,mergedAt`
- Linear: read open tickets across the team through the `linear` MCP (or
  `node "$LINEAR_CLI" states --team "$LINEAR_TEAM_KEY"` to learn the state names,
  then read the intake and Todo columns). Include closed tickets - a rejected
  idea is a duplicate too.

### 2. Ground the ideas in the repo

Read `AGENTS.md`, the README and the code that owns the surface you are thinking
about. An idea that ignores how the product already works is noise.

### 3. Propose 3-5 ideas

Each one must have: the user problem, the smallest change that addresses it, and
which part of the repo it touches. Drop anything that is a rewrite disguised as
a feature, and anything you cannot ground in the code you read.

### 4. Deduplicate

For each idea, search before filing:

```bash
gh issue list --state all --search "<keywords>"
node "$LINEAR_CLI" find --team "$LINEAR_TEAM_KEY" --fingerprint "brainstorm:<slug>"
```

Fingerprint each idea as `brainstorm:<kebab-slug>`; the same slug on a later run
must find the earlier ticket and skip it.

### 5. File

Linear first, in the intake state:

```bash
node "$LINEAR_CLI" create --team "$LINEAR_TEAM_KEY" \
  --title "<idea>" --body-file /tmp/idea.md \
  --state "New" --severity low --fingerprint "brainstorm:<slug>"
```

If Linear is unreachable, file a GitHub issue instead
(`gh issue create --label enhancement --body-file /tmp/idea.md`) and record in
the summary that the Linear leg degraded. Never retry in a loop.

### 6. Report

Write `.opencode/agent-summary.md`: the ideas filed with links, the ones dropped
as duplicates (and which ticket they duplicate), and anything that degraded.
An empty run says so explicitly - it is a complete report.

## Limits

- Read-only on the code: you propose, a human triages.
- Never file into a state other than the intake one, and never move an existing
  ticket.
- Never invent a ticket id you did not read back from the CLI.
