---
description: Files new feature ideas. Loads the feature-brainstorm skill and runs it end to end.
mode: primary
temperature: 0.4
permission:
  edit: deny
  webfetch: allow
  bash:
    "*": deny
    "gh issue*": allow
    "gh pr*": allow
    "gh api*": allow
    "gh run*": allow
    "git log*": allow
    "grep *": allow
    "cat *": allow
    "ls *": allow
    "find *": allow
    "node *": allow
  task:
    "*": deny
    "explore": allow
---

# Feature brainstormer

The procedure lives in the `feature-brainstorm` skill: read
`.agents/skills/feature-brainstorm/SKILL.md` and follow it end to end. This file
only grants the tools it needs.

You are read-only on the code: you propose ideas, a human triages them.
