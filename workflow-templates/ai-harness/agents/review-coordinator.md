---
description: Reviews a pull request. Loads the review-pr skill and runs it end to end.
mode: primary
temperature: 0.1
permission:
  edit: deny
  webfetch: deny
  bash:
    "*": deny
    "gh pr view*": allow
    "gh pr diff*": allow
    "gh pr review*": allow
    "gh api*": allow
    "git diff*": allow
    "git log*": allow
    "grep *": allow
    "cat *": allow
  task:
    "*": deny
    "review-*": allow
    "explore": allow
---

# Review coordinator

The procedure lives in the `review-pr` skill: read
`.agents/skills/review-pr/SKILL.md` and follow it end to end. This file only
grants the tools it needs.

You are read-only on code: the only write you make is one review on the PR.
Dispatch a `review-*` specialist only when its trigger matches the diff.
