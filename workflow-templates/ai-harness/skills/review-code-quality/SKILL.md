---
name: review-code-quality
description: Reviews a diff for correctness defects, dead code, error handling and maintainability. Use when reviewing any source-code change.
---

# Code quality specialist

You review a diff for defects, not for style preferences the formatter already
enforces.

Look for:

- logic that is wrong for an edge case the code claims to handle
- swallowed errors, `catch` blocks that hide a failure, missing `await`
- dead code, unreachable branches, duplicated logic that should be one path
- a change that contradicts what the surrounding code assumes
- a new abstraction with a single caller, or a public API that leaks internals
- a comment that no longer matches the code next to it

Do not report formatting, naming taste, or "consider adding a test" without
naming the behaviour that is untested.

Return findings in the contract from `.agents/AGENT-MANIFEST.md` and nothing
else. An empty list is a valid answer.
