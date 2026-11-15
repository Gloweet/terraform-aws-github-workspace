---
name: develop-ticket
description: Carries a Linear ticket or GitHub issue to a pull request. Resolve, claim, implement, run the repository gates, self-review, push and open a PR. Use when developing a ticket.
---

# Develop a ticket

You carry a ticket to a pull request. One ticket, one branch, one PR. You are the
only writer in this workflow; the specialists you dispatch are read-only.

Read `.agents/AGENT-MANIFEST.md` first: it has the finding contract, the Linear
CLI surface, the pipeline states and the run-state format. Read `AGENTS.md` next;
it lists what already broke here.

## Inputs

- `$TICKETS` - whitespace-separated references (`GLOW-181`, `#12`). Empty on a
  scheduled run.
- `$LINEAR_TEAM_KEY` - the Linear team to read state names from.
- `$LINEAR_CLI` - absolute path to `linear.mjs`.
- `$AGENT_OUTPUT_LANGUAGE` - the language of the summary; code and commits stay
  in English.

## Steps

### 1. initializer

Write `.opencode/agent-state.json` with one item per reference (or one item
holding the id `auto` for the scheduled case), every step `passes: false`, and
this run's `run_id`. Only do this when the file does not already belong to this
run - resume otherwise (see the manifest).

### 2. resolve

- `GLOW-<n>`-shaped reference: read it through the `linear` MCP (`linear_*`). If
  the MCP is unavailable, `node "$LINEAR_CLI" find --team "$LINEAR_TEAM_KEY"
  --title` is not a lookup by id - say Linear is unreachable and stop that item.
- `#<n>` or a URL: `gh issue view <n> --json title,body,labels,state`.
- No reference: **pick**. List the team's `Todo` column (the state a human
  triaged), highest priority first, and take the first item not already in
  progress. An empty column is the zero-tasks end state: write the empty summary,
  stop, and do not look at other columns.
- If the ticket is already merged or closed, stop that item and say so.

### 3. claim

Before writing code, move the ticket to `In Progress`:

```bash
node "$LINEAR_CLI" move --issue "$ID" --state "In Progress"
```

This is the lock that keeps a second agent off the same ticket. A non-zero exit
means Linear is unavailable: record it, continue on the GitHub path, and never
invent a ticket id.

### 4. existing

Search for an open PR that already carries this ticket:

```bash
gh pr list --state open --search "$ID in:title,body" --json number,headRefName,isDraft
```

- open PR found -> continue it (checkout its branch, do not open a second one)
- merged PR found -> stop, the ticket is done
- nothing -> create `feature/<id>-<slug>` off the default branch

### 5. implement

Implement the smallest change that satisfies the acceptance criteria. Read the
surrounding code first and match its conventions. Do not refactor adjacent code,
do not add abstractions the ticket does not need, and do not touch files outside
the ticket's surface unless the change genuinely requires it.

If the ticket is ambiguous in a way that changes the design, say so in the PR
body and pick the conservative reading - you cannot ask a human mid-run.

### 6. verify

Run the repo's real gates and record each result. Take the list from `AGENTS.md`;
when it is silent, detect it: `package.json` scripts (`lint`, `typecheck`,
`test`, `build`), `Dockerfile`, `terraform fmt -check` and `terraform validate`.
Install dependencies first if the gate needs them.

A failing gate is a defect in your work, not in the gate: fix it. If a gate
cannot run for an environment reason, say which and why in the PR body and the
summary - never report a gate as passing when it did not run.

### 7. review

Dispatch the `review-*` specialists that match your diff (routing table in the
`review-pr` skill). Fix every `critical` and `warning`. Record any finding
you deliberately left, with one line of reasoning.

### 8. ship

1. Commit in small, coherent commits, conventional-commit messages, English.
2. `git push -u origin <branch>`.
3. Open the PR as a draft before reviewing, so a timeout leaves a draft PR
   rather than an orphan branch:
   `gh pr create --draft --base <default branch> --title "<type>(<scope>): <summary> (<ID>)" --body-file …`
4. Body: what changed, why, the acceptance criteria and how each is met, the gate
   results, and `Closes <ID>`.
5. `gh pr ready <pr>`, then label it `ai` (`gh pr edit <pr> --add-label ai`) so
   the review workflow picks it up.
6. Move the ticket to `In Review`.

### 9. report

Write `.opencode/agent-summary.md` (and keep `agent-state.json` current) with:
the ticket, the branch and PR link, each gate's real result, the findings you
fixed, anything you skipped and why. An empty run writes `status: empty` and the
one line "Zero tasks." - that is a complete report, not a failure.

## Limits

- Never edit `.env*`, CI secrets, infrastructure state, or generated deploy
  config. Never commit a lockfile-only change.
- Never force-push another agent's branch, never rewrite published history.
- Never open more than one PR per ticket.
- Never claim a gate passed when it did not run; say "not run" and why.
