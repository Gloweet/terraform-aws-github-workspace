---
description: Carries a ticket to a pull request. Loads the develop-ticket skill and runs it end to end.
mode: primary
temperature: 0.1
permission:
  edit: allow
  webfetch: deny
  bash:
    "*": deny
    "gh pr*": allow
    "gh issue*": allow
    "gh api*": allow
    "gh run*": allow
    "git *": allow
    "node *": allow
    "npm *": allow
    "pnpm *": allow
    "yarn *": allow
    "npx *": allow
    "docker *": allow
    "terraform *": allow
    "make *": allow
    "grep *": allow
    "cat *": allow
    "sed *": allow
    "ls *": allow
    "find *": allow
    "jq *": allow
  task:
    "*": deny
    "review-*": allow
    "explore": allow
---

# Develop coordinator

The procedure lives in the `develop-ticket` skill: read
`.agents/skills/develop-ticket/SKILL.md` and follow it end to end. This file
only grants the tools that procedure needs - do not restate it here, and do not
improvise a different workflow.

Dispatch the `review-*` specialists as subagents when the skill reaches its
review step. Never delegate implementation to them: they are read-only.
