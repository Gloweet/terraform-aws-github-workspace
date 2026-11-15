locals {
  repo = {
    name        = "sample-worker"
    description = "Sample: static site built with pnpm and deployed to Cloudflare Workers"
    create_repo = true
    repo_org    = "Gloweet"
    is_private  = true
    working_dir = "terraform"

    deploy_target = "worker"
    app_dir       = "app"
    # worker_compatibility_date = "2026-01-01"
  }
  secrets = [
    {
      "name"  = "AWS_ROLE_ARN"
      "value" = var.aws_role_arn
    },
    {
      # Used by the workflow to look up org members/teams
      "name"  = "ORG_TOKEN"
      "value" = var.org_token
    },
    {
      "name"  = "CLOUDFLARE_API_TOKEN"
      "value" = var.cloudflare_api_token
    }
  ]
  vars = concat(
    [
      {
        "name"  = "TERRAFORM_VERSION"
        "value" = var.terraform_version
      },
      {
        "name"  = "AWS_REGION"
        "value" = var.aws_region
      },
      {
        # Unique per environment: "sample-worker", "sample-worker-staging", ...
        "name"  = "WORKER_NAME"
        "value" = var.worker_name
      },
      {
        "name"  = "CLOUDFLARE_ACCOUNT_ID"
        "value" = var.cloudflare_account_id
      },
    ],
    # Optional custom domain; the app workflow only adds it when non-empty.
    var.worker_route == "" ? [] : [{ "name" = "WORKER_ROUTE", "value" = var.worker_route }],
  )
}

resource "random_uuid" "bucket_id" {}

resource "aws_s3_bucket" "cache_bucket" {
  bucket = lower("${local.repo.repo_org}-${local.repo.name}-${random_uuid.bucket_id.result}")
}

module "state" {
  source              = "../../../modules/bootstrap-state"
  region              = "eu-west-3"
  state_bucket_name   = lower("${local.repo.repo_org}-${local.repo.name}-tfstate")
  dynamodb_table_name = lower("${local.repo.repo_org}-${local.repo.name}-tfstate-locks")
  tags = {
    Project   = local.repo.name
    ManagedBy = "Terraform"
  }
}

module "github_actions" {
  source              = "../../.."
  standalone          = true
  repo                = local.repo
  github_organization = var.github_organization
  github_token        = var.github_token
  environments = [
    {
      name                = "production"
      prevent_self_review = false
      can_admins_bypass   = true
      runner_group        = ["self-hosted", "linux", "x64"] # recommended: no GitHub-hosted minutes
      cache_bucket        = aws_s3_bucket.cache_bucket.bucket
      reviewers = {
        enforce_reviewers = false // activation requires a paid plan
        teams             = ["terraform-approvers"]
      }
      deployment_branch_policy = {
        branch                   = "main"
        create_branch_protection = true
        restrict_branches        = false
      }
      state_config = {
        key_prefix     = "production"
        bucket         = lower("${local.repo.repo_org}-${local.repo.name}-tfstate")
        region         = "eu-west-3"
        dynamodb_table = lower("${local.repo.repo_org}-${local.repo.name}-tfstate-locks")
        set_backend    = true
      }
      vars    = local.vars
      secrets = local.secrets
    },
    # Optional staging environment. Always set `branch` explicitly, otherwise it
    # falls back to the default branch and both environments deploy on main.
    # Remember to give it its own WORKER_NAME (and its own CLOUDFLARE_API_TOKEN
    # if it targets a different Cloudflare account).
    # {
    #   name                = "staging"
    #   prevent_self_review = false
    #   can_admins_bypass   = true
    #   runner_group        = ["self-hosted", "linux", "x64"]
    #   cache_bucket        = aws_s3_bucket.cache_bucket.bucket
    #   reviewers = {
    #     enforce_reviewers = false
    #     teams             = ["terraform-approvers"]
    #   }
    #   deployment_branch_policy = {
    #     branch                   = "staging"
    #     create_branch            = true
    #     create_branch_protection = true
    #     restrict_branches        = false
    #   }
    #   state_config = {
    #     key_prefix     = "staging"
    #     bucket         = lower("${local.repo.repo_org}-${local.repo.name}-tfstate")
    #     region         = "eu-west-3"
    #     dynamodb_table = lower("${local.repo.repo_org}-${local.repo.name}-tfstate-locks")
    #     set_backend    = true
    #   }
    #   vars    = local.vars
    #   secrets = local.secrets
    # }
  ]
}
