---
name: bootstrap-repo
description: Bootstrap a new GitHub repository with AWS OIDC, Terraform CI/CD, and app workflows. Guides through prerequisites, creates live/<app>/{aws,github} directories, and runs Terraform provisioning.
type: process
---

# Bootstrap a New GitHub Repository

Use this skill to provision a fully configured GitHub repository from scratch: AWS OIDC role, S3 state bucket, GitHub environments, branch protections, and auto-generated CI/CD workflows.

## Step 0 — Find the Best Reference App

Before scaffolding, check `live/` for an existing app that's the closest match to what's being bootstrapped (same deploy target — Docker/ECR vs React/S3 — same org, etc.) and copy from it instead of `live/sample/`. `live/sample/` is a generic template; a real, already-applied app (e.g. `live/headlamp-plugins/`) reflects the conventions actually in use — including ones not fully captured below. In this repo, **`live/headlamp-plugins/` is the canonical working reference**: Gloweet org, eu-west-3, standalone mode, PAT-based auth, single `production` environment, and (if the app needs to publish a container image) an ECR repo defined alongside the OIDC role.

## Step 1 — Check Prerequisites

Before doing anything, verify all prerequisites are met. Ask the user for each item if unclear.

### 1a. GitHub auth — PAT vs GitHub App

In practice, every app bootstrapped in this repo so far (`headlamp-plugins`, `sample`) uses **PAT-based auth** (`github_token` + `org_token` variables) — not a GitHub App. The GitHub App path exists in `providers.tf` as a commented-out alternative, with a note that app auth doesn't support setting repo environment variables/secrets, so token auth is required regardless. Default to asking for a PAT unless the user specifically wants app auth:

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
- `environments` — list of environments to create (e.g. `production`, `staging`)
- Whether this is a **standalone** deployment (recommended: `true`)
- **What the app deploy target is** — this determines which app workflow to use (see Step 2 note below):
  - React frontend → S3/CloudFront (`app_dir`, defaults to `app`) — matches the module's built-in `app.tftpl` template as-is
  - Docker container → ECR — the built-in `app-<env>.yml` template does NOT fit this case (it's React/S3-specific); needs an ECR repo in the `aws` root and a hand-written Docker build/push workflow (see below)

---

## Step 2 — Scaffold the Live Directories

Create two directories by copying from the sample:

```
live/<app_name>/aws/      ← copy from live/sample/aws/
live/<app_name>/github/   ← copy from live/sample/github/
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
    app_dir     = "app"   # React app directory, if applicable
  }
}
```

Configure the `environments` list for each environment. Example minimum:

```hcl
{
  name         = "production"
  runner_group = "ubuntu-latest"
  cache_bucket = aws_s3_bucket.cache_bucket.bucket
  deployment_branch_policy = {
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
- `.github/workflows/app-<env>.yml` (React → S3/CloudFront, with cosign signing; `overwrite_on_create = false` so it's only scaffolded once)
- `.github/actions/setup-aws/action.yml`
- `.github/actions/setup-tf-cache/action.yml`

**Docker/ECR apps:** the auto-generated `app-<env>.yml` is a React/S3 placeholder and will not work for a containerized app — replace its content by hand with a Docker build → `docker push` to ECR workflow (mirror the cosign-signing structure of the original template: build, sign, then a separate deploy job gated on the environment). Since `overwrite_on_create = false`, Terraform will not clobber the hand-written version on subsequent `apply` runs.

---

## Post-bootstrap Checklist

- [ ] Verify the repo was created at `github.com/<org>/<app_name>`
- [ ] Confirm environments exist under repo Settings → Environments
- [ ] Check that `AWS_ROLE_ARN` and `AWS_REGION` are set in each environment
- [ ] Set `IS_RELEASE = true` in the environment variable for production-like environments (enables failover S3 bucket sync)
- [ ] Set `CLOUDFRONT_ID` in the environment variable if a CloudFront distribution is used
- [ ] Trigger the app workflow manually via `workflow_dispatch` to verify the cosign signing step passes
