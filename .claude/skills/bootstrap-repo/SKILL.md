---
name: bootstrap-repo
description: Bootstrap a new GitHub repository with AWS OIDC, Terraform CI/CD, and app workflows. Guides through prerequisites, creates live/<app>/{aws,github} directories, and runs Terraform provisioning.
type: process
---

# Bootstrap a New GitHub Repository

Use this skill to provision a fully configured GitHub repository from scratch: AWS OIDC role, S3 state bucket, GitHub environments, branch protections, and auto-generated CI/CD workflows.

## Step 0 — Pick the Reference App

**Read `live/scaffolded-apps.md` first.** It lists every app already provisioned
(deploy target, environments, branches, runner, per-app quirks) and says which one to
copy for each deploy target. Prefer copying a real, already-applied app under `live/` —
it reflects the conventions actually in use, including ones not fully captured below.

When no applied app matches, copy the minimal sample for the deploy target:
`live/sample-s3/`, `live/sample-docker/` or `live/sample-worker/`, then adapt the
`deploy_target` block described in Step 2.

## Step 1 — Check Prerequisites

Before doing anything, verify all prerequisites are met. Ask the user for each item if unclear.

### 1a. GitHub auth — PAT vs GitHub App

In practice, every app bootstrapped in this repo so far (`headlamp-plugins`, `tolgee-platform`, `sample`) uses **PAT-based auth** (`github_token` + `org_token` variables) — not a GitHub App. The GitHub App path exists in `providers.tf` as a commented-out alternative, with a note that app auth doesn't support setting repo environment variables/secrets, so token auth is required regardless. Default to asking for a PAT unless the user specifically wants app auth:

- `github_token` — PAT with repo-admin scope in the target org (creates the repo, sets up environments/secrets/workflows)
- `org_token` — PAT with org read scope (used by the generated workflows themselves, e.g. to look up members/teams)

Only fall back to the GitHub App flow if the user explicitly asks for it. Required permissions on the GitHub App if used:

- Administration: Read and write
- Contents: Read and write
- Projects: Read and write
- Variables: Read and write
- Workflows: Read and write
- Members: Read and write

Required values (ask the user to provide them or confirm they are already in `live/<app>/github/.auto.tfvars`):

- `github_app_id` — visible at the top of the App settings page
- `github_app_installation_id` — visible in the URL: `github.com/organizations/<org>/settings/installations/<id>`
- PEM private key file — downloaded from the App settings, placed at `live/github_app_pem_file.pem`

If going the GitHub App route and it hasn't been created yet, stop and point the user to `docs/gihtub-app.md` for instructions.

### 1b. AWS OIDC Provider

Ask the user: "Does an OIDC provider for GitHub Actions already exist in the target AWS account?"

If yes → `create_oidc_provider = false` in `live/<app>/aws/main.tf`
If no → `create_oidc_provider = true`

### 1c. GitHub org team

A team named `terraform-approvers` must exist in the GitHub organization (required for reviewer enforcement even if `enforce_reviewers = false`).

### 1d. Required variable values

Collect from the user:

- `app_name` — the new repo name (e.g. `my-new-service`)
- `github_org` — GitHub organization name
- `aws_region` — AWS region (e.g. `eu-west-3`)
- Whether this is a **standalone** deployment (recommended: `true`)
- **What the app deploy target is** — set via `repo.deploy_target` in the GitHub root (see Step 2 note below):
  - `"s3"` (default) — React frontend → S3/CloudFront (`app_dir`, defaults to `app`)
  - `"ecr"` — Docker container → ECR. Needs an ECR repo in the `aws` root (see below) plus `repo.ecr_image_name` (defaults to repo name), `ecr_dockerfile` (default `Dockerfile`), `ecr_docker_context` (default `.`), `ecr_use_submodules` (bool, for repos that vendor plugins/deps as git submodules), `ecr_cron_schedule` (cron string, e.g. `"0 0 1 * *"` for periodic rebuilds — empty disables it)
  - `"worker"` — static site → Cloudflare Workers (static assets). Builds `app_dir` with pnpm, generates `wrangler.jsonc` on the runner, then `wrangler deploy`. Optional `repo.worker_compatibility_date` (default `2026-01-01`). Per environment, the GitHub Environment needs `WORKER_NAME`, `CLOUDFLARE_ACCOUNT_ID`, optionally `WORKER_ROUTE` (custom domain), and the `CLOUDFLARE_API_TOKEN` secret
- **How many environments** (see 1e)

Note: a `worker` app still needs the `aws` root. The generated `terraform-plan-*` /
`terraform-apply-*` workflows always use the S3/DynamoDB backend and assume the
`AWS_ROLE_ARN` role, so provision the OIDC role and state bucket even though the
deploy itself only talks to Cloudflare.

### 1e. Choose the environments

Ask which of these to create, then wire each one to its own branch:

| Environment  | Branch     | Notes                                              |
| ------------ | ---------- | -------------------------------------------------- |
| `production` | `main`     | required                                           |
| `staging`    | `staging`  | optional; set `create_branch = true`               |
| `develop`    | `develop`  | optional; set `create_branch = true`               |

Each environment produces its own `terraform-plan-<env>.yml`, `terraform-apply-<env>.yml`
and `app-<env>.yml`, triggered by that environment's branch.

**Always set `deployment_branch_policy.branch` explicitly per environment.** When it is
`null`, the module falls back to the repo default branch, so every environment ends up
triggering on `main`. The commented `staging` block in each `live/sample-*/github/main.tf`
shows the correct wiring. Also keep
`restrict_branches = false` (as every existing app does) unless the non-default branches
are protected, otherwise GitHub blocks deployments from `staging`/`develop`.

### 1f. Runner

Use the org-level **self-hosted runner** by default: it keeps GitHub-hosted minutes (and
therefore cost) at zero. `runner_group` maps to the workflow's `runs-on` and accepts
either a single label or a list of labels:

```hcl
runner_group = ["self-hosted", "linux", "x64"] # recommended: org-level self-hosted runner
runner_group = "ubuntu-latest"                 # GitHub-hosted, only when the repo needs it
```

A self-hosted runner registered at the org level (the Gloweet org has one) matches on its
labels — `self-hosted` plus the OS/arch labels it registered with (`linux`, `x64` by
default). Add a custom label to the runner if you want jobs pinned to it.

Prerequisites on a self-hosted runner used by these workflows: `git`, `curl`, `unzip`,
the AWS CLI (used directly by `setup-aws` and by the S3 sync steps), Docker (only for
`ecr` builds), and network access to github.com, AWS and Cloudflare. Node, pnpm and
Terraform are installed by the actions themselves. Do not attach this
runner to public repositories: `terraform-plan-<env>.yml` runs on `pull_request`, so
fork PRs would execute untrusted code on it.

---

## Step 2 — Scaffold the Live Directories

Create two directories, copying from the reference app picked in Step 0 (the sample
paths below are the fallback):

```
live/<app_name>/aws/      ← copy from live/<reference-app>/aws/
live/<app_name>/github/   ← copy from live/<reference-app>/github/
```

### Customize `live/<app_name>/aws/main.tf`

Update these locals:

```hcl
locals {
  aws_region          = "<aws_region>"
  github_organization = "<github_org>"
  repo_name           = "<app_name>"
}
```

**IAM role name must be unique per account.** `role_name` passed to `module "aws-federation-oidc"` is a literal string, not derived from `repo_name` — if you copy it verbatim from another app (e.g. `"github-actions-production"`) it collides with that app's already-applied role and `terraform apply` fails with `EntityAlreadyExists`. Always set it per-app, e.g. `role_name = "github-actions-${local.repo_name}-production"`.

Set `create_oidc_provider` based on the answer from step 1b.

Add any extra IAM permissions the app needs in `extra_policy_json` (e.g. ECR, SQS, etc).

**If the app publishes a Docker image**, add an ECR repo + lifecycle policy to this same `aws/main.tf` (copy the `aws_ecr_repository`/`aws_ecr_lifecycle_policy` blocks from `live/headlamp-plugins/aws/main.tf`), and extend `extra_policy_json` with an `ECRAuth` (`ecr:GetAuthorizationToken`) statement and an `ECRRepositoryPushPull` statement scoped to that repo's ARN. Output the repo URL (`ecr_repository_url`) so it can be wired into the GitHub root as a variable/environment var.

### Customize `live/<app_name>/github/main.tf`

Update:

```hcl
locals {
  repo = {
    name        = "<app_name>"
    description = "<description>"
    repo_org    = "<github_org>"
    is_private  = true
    working_dir = "terraform"
    app_dir     = "app"   # React app directory, if deploy_target = "s3" (default)

    # For Docker/ECR apps instead, set:
    # deploy_target      = "ecr"
    # ecr_image_name     = "<app_name>"   # optional, defaults to repo name
    # ecr_dockerfile     = "Dockerfile"
    # ecr_docker_context = "."
    # ecr_use_submodules = false
    # ecr_cron_schedule  = ""             # e.g. "0 0 1 * *" for periodic rebuilds

    # For Cloudflare Workers instead, set:
    # deploy_target             = "worker"
    # app_dir                   = "app"        # the build output must land in app/dist
    # worker_compatibility_date = "2026-01-01" # optional
  }
}
```

Configure the `environments` list for each environment. Example minimum:

```hcl
{
  name         = "production"
  runner_group = ["self-hosted", "linux", "x64"] # recommended; "ubuntu-latest" if the runner can't be used
  cache_bucket = aws_s3_bucket.cache_bucket.bucket
  deployment_branch_policy = {
    branch                   = "main"
    create_branch_protection = true
    restrict_branches        = false
  }
  state_config = {
    key_prefix     = "production"
    bucket         = "<org>-<app>-tfstate"
    region         = "<aws_region>"
    dynamodb_table = "<org>-<app>-tfstate-locks"
    set_backend    = true
  }
  vars    = local.vars
  secrets = local.secrets
}
```

For `staging` / `develop`, duplicate the block with `branch = "staging"` /
`branch = "develop"`, `create_branch = true`, and a distinct `key_prefix`. Give every
environment its own values in `vars` — for a `worker` app that means a distinct
`WORKER_NAME` (e.g. `<app>` vs `<app>-staging`) and its own `CLOUDFLARE_API_TOKEN` in
`secrets` if it lives in a different Cloudflare account.

Create `live/<app_name>/github/.auto.tfvars` from the example file and fill in all values.

---

## Step 3 — Provision AWS Resources

```bash
cd live/<app_name>/aws
terraform init
terraform apply
```

Note the `role_arn` output — this is the `AWS_ROLE_ARN` secret value for the GitHub environment.

---

## Step 4 — Provision GitHub Repository

Add the `role_arn` from step 3 to `live/<app_name>/github/.auto.tfvars`:

```
aws_role_arn = "<role_arn_from_step3>"
```

Then:

```bash
cd live/<app_name>/github
terraform init
terraform apply
```

This creates:

- The GitHub repository
- GitHub environments with branch protection
- Secrets and variables per environment
- `.github/workflows/terraform-plan-<env>.yml`
- `.github/workflows/terraform-apply-<env>.yml`
- `.github/workflows/app-<env>.yml` — rendered from `app.tftpl` (React → S3/CloudFront, cosign signing), `app-ecr.tftpl` (Docker → ECR, OIDC login via `setup-aws`) or `app-worker.tftpl` (static site → Cloudflare Workers, `wrangler.jsonc` generated on the runner), depending on `repo.deploy_target`. `overwrite_on_create = false` in all three cases, so it's only scaffolded once and then owned by the target repo.
- `.github/actions/setup-aws/action.yml`
- `.github/actions/setup-tf-cache/action.yml`

**Switching `deploy_target` after the repo already exists** does not retroactively rewrite `app-<env>.yml` (it's already been scaffolded and is hand-owned per above) — edit the workflow file directly in the target repo instead of re-applying Terraform for this.

---

## Post-bootstrap Checklist

- [ ] Verify the repo was created at `github.com/<org>/<app_name>`
- [ ] Confirm environments exist under repo Settings → Environments, one per branch
- [ ] Check that `AWS_ROLE_ARN` and `AWS_REGION` are set in each environment
- [ ] `deploy_target = "s3"`: set `IS_RELEASE = true` for production-like environments (enables failover S3 bucket sync) and `CLOUDFRONT_ID` if a distribution is used
- [ ] `deploy_target = "worker"`: set `WORKER_NAME` and `CLOUDFLARE_ACCOUNT_ID` (vars), `CLOUDFLARE_API_TOKEN` (secret, Workers Scripts:Edit), and `WORKER_ROUTE` if using a custom domain
- [ ] Self-hosted runner: confirm the job actually gets picked up (wrong labels leave it queued forever)
- [ ] **Add the app to `live/scaffolded-apps.md`** — deploy target, environments + branches, runner, and anything unusual, so the next bootstrap can copy it
- [ ] Trigger the app workflow manually via `workflow_dispatch` to verify the deploy (and, for `s3`, the cosign signing step) passes
