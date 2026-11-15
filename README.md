# terraform-aws-github-workspace

Need to bootstrap a github repository that **supports Terraform workflows with access to AWS resources?**

This project automates the setup and configuration of GitHub repositories including:

- GitHub environments with appropriate deployment reviews and branch protections
- Terraform CI/CD workflows (plan and apply) specific to each environment
- Integration with AWS S3 for Terraform state and workflow caching
- GitHub Action secrets and environment variables

This fork of [terraform-github-workspace](https://github.com/HappyPathway/terraform-github-workspace) adds support for:

- a standalone mode for small teams. This creates all the necessary actions inside of the bootstrapped repo, instead of centralizing them in a single repository.
- AWS OIDC connection federation

## Features

- **Environment Management**: Create and configure GitHub environments with custom settings
- **CI/CD Workflow Templates**: Auto-generated Terraform plan/apply workflows for each environment
- **AWS Integration**: Support for AWS-backed Terraform state management
- **Branch Protection**: Customizable branch policies with options for PR reviews and status checks
- **Secret Management**: Environment-specific secrets and variables for GitHub Actions

## Usage

1. If you don't have a shared tf state:

- update bootstrap/main.tf accordingly
- run:

```bash
cd bootstrap
terraform init
terraform apply
```

2. In your organization, create a team named 'terraform-approvers'.

3. Create a personal access token
   On a GitHub account that is a member of your organization, create two personal access tokens.

a. The first token is used here to setup the GitHub repository (github_token)
It must be able to manage repositories, secrets and environment variables

Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic) > Generate new token (classic).

Name it (e.g., "github_token for repo setup").

Select scopes:

- `repo` (full repo control, covers repo mgmt/secrets/vars)
- `admin:org` for org secrets
- `Workflows` to create default workflows

b. The second token must have the `read:org` scope to read the organization's teams.

Name it (e.g., "org_token for repo setup").

1. Configure the github project to create the repo.

Set `live/main.tf` accordingly.

```hcl
locals {
  repo = {
    name        = "example-repo"
    create_repo = true
    repo_org    = "YourOrgName"
    description = "Example repository managed by Terraform"
  }
}

resource "aws_s3_bucket" "cache_bucket" {
  bucket = "terraform-state-${local.repo.name}"
}

module "github_actions" {
  source = "HappyPathway/workspace/github"

  repo = local.repo

  environments = [
    {
      name         = "development"
      cache_bucket = aws_s3_bucket.cache_bucket.bucket
      deployment_branch_policy = {
        branch = "dev"
      }
    },
    {
      name         = "production"
      cache_bucket = aws_s3_bucket.cache_bucket.bucket
      reviewers = {
        enforce_reviewers = true
        teams             = ["terraform-reviewers"]
      }
      deployment_branch_policy = {
        branches = "main"
        protected_branches = true
      }
    }
  ]
}
```

5. Run terraform plan
   If the organization is not set, try running `export GITHUB_OWNER=<your_organization>`

## Requirements

- Terraform >= 0.14
- GitHub Provider
- AWS Provider (when using S3 backend)

## Components

This module creates:

1. GitHub environments with deployment review settings
2. Branch protection rules based on environment settings
3. GitHub Actions workflows for Terraform plan/apply
4. Terraform backend configuration files
5. Environment-specific secrets and variables

## Environment Configuration

Each environment can be configured with:

- Reviewers (users and teams)
- Deployment branch policies
- Wait timers for deployments
- AWS S3 backend settings
- Environment-specific secrets and variables

## CI/CD Workflow

The module generates GitHub Actions workflows that:

1. Initialize Terraform with the correct backend
2. Plan changes with environment-specific variables
3. Apply changes after approval (in the target environment)
4. Use S3 for caching Terraform artifacts between steps

## Advanced Features

- Self-review prevention
- Custom branch policies
- Admin bypass settings
- Support for custom GitHub Action composite actions

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_github"></a> [github](#requirement\_github) | 6.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_actions_environment_variables"></a> [actions\_environment\_variables](#module\_actions\_environment\_variables) | ./modules/actions_environment_variables | n/a |
| <a name="module_context"></a> [context](#module\_context) | ./modules/context | n/a |
| <a name="module_repo"></a> [repo](#module\_repo) | ./modules/repo-github | n/a |

## Resources

| Name | Type |
|------|------|
| [github_branch.branch](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/branch) | resource |
| [github_branch_protection.branch](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/branch_protection) | resource |
| [github_branch_protection.branch_pattern](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/branch_protection) | resource |
| [github_repository_deployment_branch_policy.this](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_deployment_branch_policy) | resource |
| [github_repository_environment.this](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_environment) | resource |
| [github_repository_environment_deployment_policy.this](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_environment_deployment_policy) | resource |
| [github_repository_file.ai_harness_develop_ticket](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.ai_harness_feature_brainstorm](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.ai_harness_review](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.ai_harness_static](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.apply](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.backend_tf](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.env_backend_tf](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.main_tf](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.plan](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_app](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_app_ecr](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_app_worker](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_apply](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_plan](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_setup_aws_action](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.standalone_setup_tf_cache_action](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_repository_file.varfiles](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/resources/repository_file) | resource |
| [github_organization_teams.all](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/data-sources/organization_teams) | data source |
| [github_repository.repo](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/data-sources/repository) | data source |
| [github_repository.repository](https://registry.terraform.io/providers/integrations/github/6.6.0/docs/data-sources/repository) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_composite_action_repos"></a> [composite\_action\_repos](#input\_composite\_action\_repos) | n/a | <pre>object({<br>    checkout        = optional(string, "gh-actions-checkout@v4")<br>    aws_auth        = optional(string, "aws-auth@main")<br>    setup_terraform = optional(string, "gh-actions-terraform@v1")<br>    terraform_init  = optional(string, "terraform-init@main")<br>    terraform_plan  = optional(string, "terraform-plan@main")<br>    terraform_apply = optional(string, "terraform-apply@main")<br>    gh_auth         = optional(string, "gh-auth@main")<br>    s3_cleanup      = optional(string, "s3-cleanup@main")<br>  })</pre> | `{}` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | List of environments with their configurations | <pre>list(object({<br>    # Name of the environment<br>    name                = string<br>    prevent_self_review = optional(bool, false)  # Flag to prevent self review<br>    wait_timer          = optional(number, null) # Wait timer for review<br>    # Reviewers configuration<br>    can_admins_bypass = optional(bool, true) # Flag to allow admins to bypass<br>    # Runner labels used for `runs-on`: either a single label ("ubuntu-latest") or a<br>    # list (["self-hosted", "linux", "x64"]).<br>    runner_group = optional(any, "self-hosted")<br>    reviewers = optional(object({<br>      users             = optional(list(string), []) # List of user reviewers<br>      teams             = optional(list(string), []) # List of team reviewers<br>      enforce_reviewers = optional(bool, false)      # Flag to enforce reviewers<br>      }), {<br>      users = []<br>      teams = []<br>    })<br>    cache_bucket = string<br>    # Deployment branch policy configuration<br>    deployment_branch_policy = optional(object({<br>      branch                   = optional(string)      # Branch name<br>      branch_pattern           = optional(string)      # Branch pattern<br>      create_branch            = optional(bool, false) # Flag to create branch<br>      create_branch_protection = optional(bool, true)  # Flag to create branch protection<br>      protected_branches       = optional(bool, true)  # Flag to protect branches<br>      custom_branch_policies   = optional(bool, false) # Flag to enable custom branch policies<br>      enforce_admins           = optional(bool, false) # Flag to enforce admin rules<br>      restrict_branches        = optional(bool, true)  # Flag to create policy<br>      required_status_checks = optional(object({<br>        strict   = optional(bool, true) # Flag to enforce strict status checks<br>        contexts = list(string)         # List of status check contexts<br>        }), {<br>        strict   = false<br>        contexts = []<br>      })<br>      required_pull_request_reviews = optional(object({<br>        dismiss_stale_reviews           = optional(bool, true) # Flag to dismiss stale reviews<br>        require_code_owner_reviews      = optional(bool, true) # Flag to require code owner reviews<br>        required_approving_review_count = optional(number, 1)  # Number of required approving reviews<br>        }), {<br>        dismiss_stale_reviews           = true<br>        require_code_owner_reviews      = true<br>        required_approving_review_count = 1<br>      })<br>      }), {<br>      branch                 = "main"<br>      create_branch          = false<br>      protected_branches     = true<br>      custom_branch_policies = false<br>    })<br><br>    # State configuration for Terraform<br>    state_config = optional(object({<br>      bucket         = optional(string)      # S3 bucket name<br>      key_prefix     = optional(string)      # Key prefix for the state file<br>      region         = optional(string)      # AWS region<br>      dynamodb_table = optional(string)      # DynamoDB table for state locking<br>      set_backend    = optional(bool, false) # Flag to set backend<br>      }), null<br>    )<br><br>    # Secrets for GitHub Actions<br>    secrets = optional(list(object({<br>      name  = string # Secret name<br>      value = string # Secret value<br>    })), [])<br><br>    # Variables for GitHub Actions<br>    vars = optional(list(object({<br>      name  = string # Variable name<br>      value = string # Variable value<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_github_organization"></a> [github\_organization](#input\_github\_organization) | n/a | `string` | n/a | yes |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | n/a | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Configuration for the GitHub repository | <pre>object({<br>    collaborators = optional(map(string), {})<br>    create_repo   = optional(bool, true)<br>    description   = optional(string, "")<br>    enforce_prs   = optional(bool, true)<br>    codeowners    = optional(string, "")<br>    vars = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>    secrets = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>    admin_teams            = optional(list(string), [])<br>    create_codeowners      = optional(bool, false)<br>    pull_request_bypassers = optional(list(string), [])<br>    github_organization_teams = optional(list(object({<br>      slug = string<br>      id   = string<br>    })), [])<br>    auto_init          = optional(bool, true)<br>    is_private         = optional(bool, false)<br>    is_template        = optional(bool, false)<br>    template_repo_org  = optional(string, null)<br>    template_repo      = optional(string, null)<br>    name               = string<br>    repo_org           = string<br>    repo_topics        = optional(list(string), [])<br>    archive_on_destroy = optional(bool, false)<br>    extra_files = optional(list(object({<br>      path    = string,<br>      content = string<br>    })), [])<br>    managed_extra_files = optional(list(object({<br>      path    = string,<br>      content = string<br>    })), [])<br>    working_dir = optional(string, ".")<br>    app_dir     = optional(string, "app")<br><br>    # App workflow deploy target:<br>    # - "s3"     React build -> S3/CloudFront (default)<br>    # - "ecr"    Docker build -> ECR<br>    # - "worker" static site build -> Cloudflare Workers (static assets)<br>    deploy_target      = optional(string, "s3")<br>    ecr_image_name     = optional(string, null) # defaults to repo name if null<br>    ecr_dockerfile     = optional(string, "Dockerfile")<br>    ecr_docker_context = optional(string, ".")<br>    ecr_use_submodules = optional(bool, false)<br>    ecr_cron_schedule  = optional(string, "") # e.g. "0 0 1 * *"; empty disables the schedule trigger<br><br>    # Cloudflare Workers settings (deploy_target = "worker")<br>    worker_compatibility_date = optional(string, "2026-01-01")<br><br>    # AI harness: opencode agents, Agent Skills and the scheduled<br>    # develop-ticket / feature-brainstorm workflows. Off by default. Enabling it<br>    # requires the repo-level secrets and variables listed in the bootstrap<br>    # skill (LiteLLM + Linear), and a runner that can reach the LiteLLM gateway.<br>    ai_harness        = optional(bool, false)<br>    ai_harness_runner = optional(any, ["self-hosted", "linux", "x64"])<br>    ai_harness_model  = optional(string, "litellm/opencode/glm-5.2")<br>  })</pre> | n/a | yes |
| <a name="input_standalone"></a> [standalone](#input\_standalone) | n/a | `bool` | `false` | no |
| <a name="input_state_config"></a> [state\_config](#input\_state\_config) | Configuration for Terraform state storage | <pre>object({<br>    bucket         = optional(string)<br>    key            = optional(string)<br>    region         = optional(string)<br>    dynamodb_table = optional(string)<br>    set_backend    = optional(bool, false)<br>    key_prefix     = optional(string, "terraform-state-files")<br>  })</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
