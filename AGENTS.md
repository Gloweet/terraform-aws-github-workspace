# AI Project guidance

## Approach

- Read existing files before writing. Don't re-read unless changed.
- Thorough in reasoning, concise in output.
- Skip files over 100KB unless required.
- No sycophantic openers or closing fluff.
- No emojis or em-dashes.
- Do not guess APIs, versions, flags, commit SHAs, or package names. Verify by reading code or docs before asserting.

## Purpose

This is a **Terraform module** that bootstraps GitHub repositories with:

- AWS OIDC federation for GitHub Actions
- GitHub environments, branch protection, and deployment policies
- Auto-generated CI/CD workflow files (plan/apply/app) committed directly into the target repo
- S3 state backend + DynamoDB locking per environment

It is used as a **module source** from `live/<app-name>/github/main.tf` — one directory per bootstrapped app. `live/scaffolded-apps.md` inventories the apps already provisioned; read it before copying a template.

## Key Commands

```bash
# Bootstrap S3 state bucket (one-time, per app)
cd bootstrap && terraform init && terraform apply

# Provision AWS OIDC role for a new app
cd live/<app>/aws && terraform init && terraform apply

# Provision GitHub repo + environments + workflows
cd live/<app>/github && terraform init && terraform apply

# Validate templates render correctly (no plan needed)
cd live/<app>/github && terraform validate
```

## Architecture

### Two-layer provisioning per app

Each app under `live/<app>/` has two independent Terraform roots:

| Directory            | Provider | What it creates                                        |
| -------------------- | -------- | ------------------------------------------------------ |
| `live/<app>/aws/`    | AWS      | OIDC role, S3 state bucket, DynamoDB lock table        |
| `live/<app>/github/` | GitHub   | Repo, environments, branch protections, workflow files |

The AWS role ARN output from the first root is passed as a secret into the second.

### Module root (`/`)

The root of this repo **is the reusable module** consumed via `source = "../../.."` from live configs. Core files:

- `repo.tf` — creates/imports the GitHub repo via `modules/repo-github` (vendored copy of `HappyPathway/repo/github`; the upstream `HappyPathway/terraform-github-repo` GitHub repo now 404s, so this module is no longer fetched externally — update the vendored copy in place if changes are needed)
- `main.tf` — `github_repository_environment`, deployment branch policy, deployment policy
- `context.tf` + `modules/context/` — computes per-environment derived values (review users/teams, branch policy flags)
- `repo_files_standalone.tf` — generates and commits workflow YAML files into the target repo using `templatefile()`
- `repo_files_base.tf`, `repo_files_centralized.tf` — non-standalone variants (centralized composite actions)
- `optional_branch.tf` — optionally creates the deployment branch

### Standalone vs. centralized mode

Set `standalone = true` in the module call (recommended for small teams). This embeds composite actions directly in the target repo under `.github/actions/` instead of referencing a shared actions repo.

### Workflow templates (`workflow-templates/`)

`.tftpl` files rendered via `templatefile()` and committed as GitHub Actions YAML. Variables use `${var}` syntax; GitHub Actions expressions use `$${{ }}` (double-dollar to escape Terraform interpolation).

- `standalone/terraform-plan.tftpl` / `terraform-apply.tftpl` — Terraform CI for each environment
- `standalone/app.tftpl` — React app build → S3 sync → CloudFront invalidation (used when `repo.deploy_target = "s3"`, the default)
- `standalone/app-ecr.tftpl` — Docker build → push to ECR, with optional git-submodule change detection and cron schedule (used when `repo.deploy_target = "ecr"`; set `repo.ecr_image_name`, `ecr_dockerfile`, `ecr_docker_context`, `ecr_use_submodules`, `ecr_cron_schedule`)
- `standalone/app-worker.tftpl` — static site build → Cloudflare Workers (used when `repo.deploy_target = "worker"`; `wrangler.jsonc` is generated on the runner from `WORKER_NAME`, `CLOUDFLARE_ACCOUNT_ID`, optional `WORKER_ROUTE` and the `CLOUDFLARE_API_TOKEN` secret, configurable compatibility date via `repo.worker_compatibility_date`)
- `standalone/actions/setup-aws.tftpl` / `setup-tf-cache.tftpl` — composite actions

The three `app*.tftpl` templates all render to the same file, `.github/workflows/app-<env>.yml`, gated by `repo.deploy_target` so only one is ever created — `overwrite_on_create = false` applies to all of them, so once scaffolded the file is owned by the target repo.

`runs_on` in every template is rendered from `local.runs_on` (see `locals.tf`) via `jsonencode()`, so `runner_group` accepts either a label string (`"ubuntu-latest"`) or a label list (`["self-hosted", "linux", "x64"]`). Prefer the org-level self-hosted runner to avoid GitHub-hosted minutes.

### Adding a new app

1. Read `live/scaffolded-apps.md` and copy the closest existing app, otherwise the matching `live/sample-<target>/` → `live/<new-app>/aws/` and `live/<new-app>/github/`, then update locals
2. Run AWS root first (outputs `role_arn`), then GitHub root
3. The module auto-creates the repo, environments, branch protections, and pushes workflow files
4. Add the new app to `live/scaffolded-apps.md`

## Important conventions

- `$${{ }}` in `.tftpl` files escapes to `${{ }}` in the rendered GitHub Actions YAML
- `overwrite_on_create = false` on `standalone_app` intentionally — app workflow is bootstrapped once and then owned by the target repo
- `overwrite_on_create = true` on plan/apply/action files — always kept in sync by Terraform
- Environment secrets/vars are defined in `live/<app>/github/main.tf` and passed into `var.environments[*].secrets` / `.vars`
- AWS OIDC provider creation is controlled by `create_oidc_provider` in `modules/aws-federation-oidc` — set `false` when the provider already exists in the AWS account
- `role_name` passed to `module "aws-federation-oidc"` is a literal string, not derived from the app name — IAM role names are unique per AWS account, so copying it verbatim between apps (e.g. `"github-actions-production"`) causes `EntityAlreadyExists` on the second app. Always scope it, e.g. `"github-actions-<repo_name>-production"`
- In practice every app so far authenticates the `github` provider with a PAT (`github_token` + `org_token`), not a GitHub App — GitHub App auth can't set repo environment secrets/vars, so token auth is required regardless of which path is set up

## Prerequisites for a new app

1. A GitHub PAT with `repo` + `admin:org` + `Workflows` scopes (`github_token`), and a second PAT with `read:org` scope (`org_token`) — this is the auth path every app actually uses today (see convention above). GitHub App auth is a documented alternative in `providers.tf` (see `docs/gihtub-app.md`) but is unused in practice since it can't set repo environment secrets/vars.
2. AWS OIDC provider already exists in the target account (or set `create_oidc_provider = true`)
3. A team named `terraform-approvers` in the GitHub org (for reviewer enforcement)
