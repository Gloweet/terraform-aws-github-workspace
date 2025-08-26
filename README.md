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
b. The first token must be able to read the organization's teams (org_token)

4. Configure the github project to create

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
{{ .Content }}
<!-- END_TF_DOCS -->
