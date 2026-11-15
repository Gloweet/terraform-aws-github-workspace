---
name: review-pr
description: Reviews a pull request by routing the diff to the specialist review skills, then posting one consolidated review with an approve, comment or request-changes decision. Use when reviewing a PR.
---

# Review a pull request

You review a pull request. You never edit code, never push, and never change the
branch. Your only writes are one review on the PR, via `gh pr review`.

The finding contract and the list of specialists live in
`.agents/AGENT-MANIFEST.md`; read it first. A specialist is only invoked when
its trigger matches - do not run all four "just in case".

## Steps

### 1. Resolve the PR

`gh pr view <ref> --json number,title,body,baseRefName,headRefName,files`.
If the reference is missing or ambiguous, stop and say which forms you accepted.

### 2. Read the diff

`gh pr diff <ref>`. Read the ticket too, when the PR body links one (Linear via
the `linear` MCP, GitHub via `gh issue view`): a defect is a defect against the
acceptance criteria, not against your taste.

### 3. Route

| Changed files / surface                                   | Specialist            |
| --------------------------------------------------------- | --------------------- |
| any source file                                           | `review-code-quality` |
| auth, session, input parsing, SQL/shell, secrets, fetch   | `review-security`     |
| query, loop over fetched data, rendering, payload          | `review-performance`  |
| new export, new config flag, changed behaviour            | `review-documentation` |

Code quality runs on every code diff. The other three run only when the table
matches; a docs-only or config-only PR may invoke none.

### 4. Dispatch

One `task` call per specialist, each with: the PR number, the base and head
refs, the list of changed files, and the ticket's acceptance criteria when there
is one. Give them the diff context they need - they cannot see this conversation.

### 5. Consolidate

Merge the returned findings, deduplicate, and drop a finding only with a
one-line reason. Carry every `critical` and `warning` verbatim into the review.

### 6. Post one review

Use `gh pr review <ref> --comment|--approve|--request-changes --body-file …`.

- any `critical` -> `--request-changes`
- any `warning` -> `--comment`, unless a critical is present
- only `suggestion`, or nothing -> `--approve` with one line saying what you
  checked
- a security finding is never downgraded because "it is only internal"

Always append a marker line to the body so a re-run knows which head was
reviewed:

```
ai-review head=<head sha>
```

Format the body as a markdown list, one line per finding:
`- (severity) file:line - message`.

### 7. Report

Write `.opencode/agent-summary.md` with the decision, the findings carried into
the review, and anything you dropped with its reason. Write it for a human who
has not seen this conversation.

## Limits

- Read `AGENTS.md` before acting; it records traps that already shipped here.
- Never report a finding without a `file` and a `message`.
- Never approve a PR whose diff you did not read.
- Never edit, push, or resolve a thread on someone else's behalf.
