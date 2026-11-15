# Agent manifest

Single registry for the opencode agents in this repository. Coordinators read it
before fanning out so nothing is invented on the fly, and every subagent returns
the same shape, so no coordinator has to re-parse free prose.

Companion files:

- `.agents/skills/` — the procedures and specialist checklists, one folder per
  skill with a `SKILL.md` (Agent Skills format: YAML `name` + `description`, then
  the Markdown instructions). opencode discovers this directory natively, and so
  does any other Agent Skills client.
- `opencode.jsonc` — provider-independent config: the read-only Linear MCP server
  and the per-agent tool gating.
- `scratchpad.md` — gitignored per-run progress log written by the coordinators.
- `agent-state.json` — gitignored structured run state (see "Resuming" below).

## Layout: agents vs skills

An **agent** is runtime config: which tools it may use, which model, whether it
may edit. A **skill** is the instruction set it follows. They are split so the
instructions stay portable and the permission grant stays explicit:

| Path                            | What it is                                                       |
| ------------------------------- | ---------------------------------------------------------------- |
| `.agents/skills/<name>/SKILL.md` | the procedure or checklist (portable Agent Skills format)        |
| `.opencode/agents/<name>.md`     | the opencode agent: permissions + "follow the `<name>` skill"     |
| `.opencode/commands/<name>.md`   | the TUI entry point (`/ai-review`, `/ai-develop`, `/ai-autofix`) |

Keep a procedure in exactly one place. An agent file that restates a skill is a
bug: the two drift and the skill stops being the source of truth.

## Entry points

| Trigger                                     | Agent                 | Skill              | Workflow / command                   |
| ------------------------------------------- | --------------------- | ------------------ | ------------------------------------ |
| Daily schedule, or `workflow_dispatch`      | `develop-coordinator` | `develop-ticket`   | `.github/workflows/develop-ticket.yml` |
| `/ai-develop` in the TUI                    | `develop-coordinator` | `develop-ticket`   | `.opencode/commands/ai-develop.md`   |
| PR labelled `ai`, or `workflow_dispatch`    | `review-coordinator`  | `review-pr`        | `.github/workflows/ai-review.yml`    |
| `/ai-review <pr>` in the TUI                | `review-coordinator`  | `review-pr`        | `.opencode/commands/ai-review.md`    |
| `/ai-autofix <pr> <ticket>` in the TUI      | `develop-coordinator` | - (command body)   | `.opencode/commands/ai-autofix.md`   |
| Weekly schedule                             | `feature-brainstormer`| `feature-brainstorm` | `.github/workflows/feature-brainstorm.yml` |

Headless runs go through `bash scripts/ai-model-run.sh` (one `opencode run` per agent)
and `bash scripts/ai-autofix.sh` (review half, then a separate-context fix half).
Every scheduled workflow installs opencode and points it at the LiteLLM gateway
through `.github/actions/setup-opencode`, so adding a workflow means calling that
action, never re-declaring a provider or model.

## Coordinator -> subagent graph

```
develop-coordinator ──┬─► review-code-quality   (loads the review-code-quality skill)
  (develop-ticket)    ├─► review-security       (loads the review-security skill)
                      ├─► review-performance    (loads the review-performance skill)
                      └─► review-documentation  (loads the review-documentation skill)

review-coordinator ──► same four, for a PR diff (posts the review, never edits)
  (review-pr)

feature-brainstormer ► no subagent: surveys the board, files ideas
  (feature-brainstorm)
```

A specialist is only invoked when its trigger condition matches. "Run it just in
case" is discouraged, and an empty finding list counts as a pass.

## The four specialists

| Agent                  | Skill                    | Invoked when                                                                        | Returns  |
| ---------------------- | ------------------------ | ----------------------------------------------------------------------------------- | -------- |
| `review-code-quality`  | `review-code-quality`    | any source-code diff                                                                | findings |
| `review-security`      | `review-security`        | auth/session, user input, SQL/shell, secrets, external calls, file and env handling | findings |
| `review-performance`   | `review-performance`     | loops over fetched data, queries, rendering, large payloads                         | findings |
| `review-documentation` | `review-documentation`   | new exported function, new config flag, or a behaviour change a reader must know    | findings |

## Finding contract

Every specialist returns a list (possibly empty) of findings in exactly this shape:

```
file: <repo-relative path>
line: <integer, or 0 when the finding is file-level>
category: <code-quality | documentation | performance | security>
severity: <critical | warning | suggestion>
message: <one sentence: what is wrong, and why it matters here>
```

`critical` = data loss, security hole, broken production behaviour. `warning` = a
real defect or regression risk. `suggestion` = improvement or polish. Nothing
else: no praise, no "looks good", no summary of what the diff does, no finding
without a `file` and a `message`. An empty list is a valid, complete answer.

Coordinators carry every `critical` and `warning` forward verbatim. A finding may
be dropped only with a one-line reason ("superseded by X", "not reachable in
production"), never silently.

## Resuming an interrupted run

The runner is ephemeral, so the only state that survives a crashed job is what
the workflow uploads as an artifact (`.opencode/scratchpad.md` and
`.opencode/agent-state.json`).

- **Same job, restarted agent**: read the scratchpad and the state file first and
  continue from there.
- **Next scheduled run**: the previous artifact is not downloaded automatically;
  the summary tells you what the last run did. Re-verify anything it claims
  against `git`/`gh`/Linear before trusting it.
- **Never start a second unit of work for the same ticket.** If the scratchpad
  says a branch or PR exists, continue it.
- **Only truncate the scratchpad when you genuinely start fresh.**
- **Re-verify before trusting**: a scratchpad records what a previous attempt
  believed. Confirm an issue filed, a branch pushed or a ticket moved with
  `gh`/`git`/the Linear CLI.

## Run state (structured resume)

Coordinators keep `.opencode/agent-state.json` next to `.opencode/scratchpad.md`.
It is a list of items with a `passes` boolean per step, so the only thing an
agent ever changes is a status, which is what makes the file survive across
sessions:

```jsonc
{
  "schema_version": 1,
  "run_id": "…", // GITHUB_RUN_ID in CI, an ISO timestamp locally
  "workflow": "develop-ticket",
  "updated_at": "…",
  "items": [
    {
      "id": "GLOW-181",
      "description": "carry GLOW-181 to a pull request",
      "passes": false,
      "steps": [
        { "name": "resolve", "passes": true },
        { "name": "claim", "passes": true },
        { "name": "implement", "passes": true },
        { "name": "verify", "passes": false },
        { "name": "review", "passes": false },
        { "name": "ship", "passes": false },
        { "name": "report", "passes": false }
      ],
      "artifacts": { "branch": "feature/…", "pr": 23 },
      "blockers": []
    }
  ]
}
```

Rules:

- **Edit only `passes`** (and write an artifact key the first time a phase
  produces one). Never rewrite the file, never reorder items or steps.
- **Write atomically**: temp file, then `mv` over the target.
- **Resume = the first unfinished step** of the first unfinished item.
- **One item per ticket.** A fresh invocation resets the file with this run's
  `run_id`; a resumed one keeps it.

## Writing to Linear

Reads go through the read-only Linear MCP (`opencode.jsonc`). Writes go through
`scripts/linear.mjs`, invoked as `node "$LINEAR_CLI"` (the workflows stage it
outside the worktree, because the develop agent switches branches).

```bash
node "$LINEAR_CLI" states --team "$LINEAR_TEAM_KEY"
node "$LINEAR_CLI" find   --team "$LINEAR_TEAM_KEY" --fingerprint "<fp>"
node "$LINEAR_CLI" labels --team "$LINEAR_TEAM_KEY" --names security,docs
node "$LINEAR_CLI" create --team "$LINEAR_TEAM_KEY" --title "…" \
     --body-file body.md --state "New" --severity high --fingerprint "brainstorm:<slug>"
node "$LINEAR_CLI" move   --issue GLOW-181 --state "In Progress"
```

- `create` prints the issue as JSON and appends a `Fingerprint:` line to the
  description, so dedup works whether a finding landed in Linear or GitHub.
- **A non-zero exit means Linear is unavailable, not that the run failed.** Fall
  back to GitHub issues, record it in the summary, and carry on. Never retry in a
  loop, and never invent a ticket id you did not read back.
- `--severity high|medium|low` maps to Linear priority High/Medium/Low.

### Pipeline states

| State         | Meaning                                         | Who may move a ticket into it      |
| ------------- | ----------------------------------------------- | ---------------------------------- |
| `New`         | Intake: brainstormed ideas land here            | `feature-brainstormer` (create)    |
| `Todo`        | Triaged ready-to-work; the only column agents pick from | a human - never an agent |
| `In Progress` | Claimed (the lock against a second agent)       | `develop-coordinator` (claim)      |
| `In Review`   | PR open, waiting for a human                    | `develop-coordinator` (ship)       |

State names drift: go through the CLI's tolerant state matching rather than
hard-coding a name.

## Model routing and failover

Both the local scripts and CI run agents through **LiteLLM**, which owns model
routing and failover server-side. Local runs default to `litellm/claude-sonnet-5`
(your config's `litellm` provider, see the comment block in
`scripts/ai-model-run.sh`); CI defaults to `litellm/opencode/glm-5.2` because it
has no Anthropic OAuth token to forward. Each `opencode run` is its own process,
so two agents never share a model context.

## Shared limits

- Read `AGENTS.md` before acting.
- Never edit `.env*`, CI secrets, infrastructure state, or generated deploy
  config. Do not commit lockfile-only churn.
- Human-readable output in `${AGENT_OUTPUT_LANGUAGE}` (French by default); code,
  identifiers, commit messages, branch names and PR titles in English.
- Specialists are read-only (`edit: deny`).
