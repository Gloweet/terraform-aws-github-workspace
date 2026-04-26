# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a **Terraform module** that bootstraps GitHub repositories with:
- AWS OIDC federation for GitHub Actions
- GitHub environments, branch protection, and deployment policies
- Auto-generated CI/CD workflow files (plan/apply/app) committed directly into the target repo
- S3 state backend + DynamoDB locking per environment

It is used as a **module source** from `live/<app-name>/github/main.tf` — one directory per bootstrapped app.

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

| Directory | Provider | What it creates |
|---|---|---|
| `live/<app>/aws/` | AWS | OIDC role, S3 state bucket, DynamoDB lock table |
| `live/<app>/github/` | GitHub | Repo, environments, branch protections, workflow files |

The AWS role ARN output from the first root is passed as a secret into the second.

### Module root (`/`)

The root of this repo **is the reusable module** consumed via `source = "../../.."` from live configs. Core files:

- `repo.tf` — creates/imports the GitHub repo via `HappyPathway/repo/github`
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
- `standalone/app.tftpl` — React app build → S3 sync → CloudFront invalidation
- `standalone/actions/setup-aws.tftpl` / `setup-tf-cache.tftpl` — composite actions

### Adding a new app

1. Copy `live/sample/aws/` → `live/<new-app>/aws/` and update locals
2. Copy `live/sample/github/` → `live/<new-app>/github/` and update locals + environments
3. Run AWS root first (outputs `role_arn`), then GitHub root
4. The module auto-creates the repo, environments, branch protections, and pushes workflow files

## Important conventions

- `$${{ }}` in `.tftpl` files escapes to `${{ }}` in the rendered GitHub Actions YAML
- `overwrite_on_create = false` on `standalone_app` intentionally — app workflow is bootstrapped once and then owned by the target repo
- `overwrite_on_create = true` on plan/apply/action files — always kept in sync by Terraform
- Environment secrets/vars are defined in `live/<app>/github/main.tf` and passed into `var.environments[*].secrets` / `.vars`
- AWS OIDC provider creation is controlled by `create_oidc_provider` in `modules/aws-federation-oidc` — set `false` when the provider already exists in the AWS account

## Prerequisites for a new app

1. GitHub App created in org developer settings with permissions: Administration, Contents, Projects, Variables, Workflows, Members (R/W) — see `docs/gihtub-app.md`
2. GitHub App installed on the org and installation ID noted
3. AWS OIDC provider already exists in the target account (or set `create_oidc_provider = true`)
4. A team named `terraform-approvers` in the GitHub org (for reviewer enforcement)
