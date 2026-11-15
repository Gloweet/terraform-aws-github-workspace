# Scaffolded apps

Inventory of the apps already provisioned from this workspace. **Read this first when
bootstrapping a new repository**: copy the closest app below, or the minimal sample for
the deploy target (`live/sample-s3/`, `live/sample-docker/`, `live/sample-worker/`), then
update its locals.

Keep it current: adding a row here is the last step of every bootstrap.

| App               | Live config             | Deploy target | Environments (branch) | Runner          | Notes                                                                    |
| ----------------- | ----------------------- | ------------- | --------------------- | --------------- | ------------------------------------------------------------------------ |
| `headlamp-plugins` | `live/headlamp-plugins/` | `ecr`     | `production` (`main`) | `ubuntu-latest` | Docker image, git submodules, monthly rebuild cron `0 0 1 * *`            |
| `tolgee-platform`  | `live/tolgee-platform/`  | `ecr`     | `production` (`main`) | `ubuntu-latest` | Docker image, exposes `ECR_REPOSITORY_URL` as an environment variable     |
| `sample-s3`        | `live/sample-s3/`        | `s3`      | `production` (`main`) | `self-hosted`   | Minimal template, never applied                                           |
| `sample-docker`    | `live/sample-docker/`    | `ecr`     | `production` (`main`) | `self-hosted`   | Minimal template, ECR repo + IAM in `aws/`, never applied                 |
| `sample-worker`    | `live/sample-worker/`    | `worker`  | `production` (`main`) | `self-hosted`   | Minimal template for Cloudflare Workers, never applied                    |

Shared defaults across all apps: GitHub org `Gloweet`, AWS region `eu-west-3`,
`standalone = true`, PAT auth (`github_token` + `org_token`), state bucket
`<org>-<app>-tfstate` + DynamoDB table `<org>-<app>-tfstate-locks`, a single
`production` environment unless stated otherwise. New apps should use the org-level
self-hosted runner (`runner_group = ["self-hosted", "linux", "x64"]`) to avoid
GitHub-hosted minutes.

## Which app to copy

- **Docker image -> ECR**: `live/headlamp-plugins/` (submodules, cron) or
  `live/tolgee-platform/` (plain) for a real app; `live/sample-docker/` for the minimal
  skeleton.
- **Static site -> S3/CloudFront**: `live/sample-s3/`.
- **Static site -> Cloudflare Workers**: `live/sample-worker/`.

## Per-app details

### headlamp-plugins

- `deploy_target = "ecr"`, `ecr_image_name = "headlamp-plugins"`,
  `ecr_use_submodules = true`, `ecr_cron_schedule = "0 0 1 * *"`.
- AWS role: `github-actions-production` (this is the reason new apps must use a
  scoped name like `github-actions-<app>-production`).
- `aws/main.tf` also creates the ECR repository, its lifecycle policy, and the
  ECR push/pull IAM statements.

### tolgee-platform

- `deploy_target = "ecr"`, `ecr_image_name = "tolgee-platform"`.
- AWS role: `github-actions-tolgee-platform-production`.
- `ECR_REPOSITORY_URL` is set as an environment variable from the `aws` root output.

### sample-s3 / sample-docker / sample-worker

- Single `production` environment on `main`, with a commented `staging` block showing
  the correct multi-branch wiring (`branch`, `create_branch`, distinct `key_prefix`).
- `sample-docker/aws` creates the ECR repository and prints `ecr_repository_url` for
  the github root's `ECR_REPOSITORY_URL` variable.
- `sample-worker` still provisions an AWS role and state bucket: the generated
  terraform plan/apply workflows need the S3 + DynamoDB backend even though the deploy
  itself only talks to Cloudflare.
- None of the samples are applied. They exist to be copied.
