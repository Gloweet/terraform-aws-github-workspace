locals {
  repo = {
    name        = "sample-app"
    description = "Your workflows in your browser, one click away"
    create_repo = true
    repo_org    = "gloweet"
    is_private  = true
    working_dir = "terraform"
  }
  secrets = [
    {
      "name"  = "AWS_ROLE_ARN"
      "value" = var.aws_role_arn
    },
    {
      # Get organization members & teams
      "name"  = "ORG_TOKEN"
      "value" = var.org_token
    },
    {
      "name"  = "SLACK_WEBHOOK_URL"
      "value" = var.slack_webhook_url
    }
    # {
    #   "name"  = "GH_APP_PEM_FILE"
    #   "value" = file(var.github_app_pem_file)
    # }
  ]
  vars = [
    # {
    #   "name"  = "GH_APP_INSTALLATION_ID"
    #   "value" = var.github_app_installation_id
    # },
    {
      "name"  = "TERRAFORM_VERSION"
      "value" = var.terraform_version
    },
    {
      "name"  = "AWS_REGION"
      "value" = var.aws_region
    }
  ]
}

resource "random_uuid" "bucket_id" {}

resource "aws_s3_bucket" "cache_bucket" {
  bucket = lower("${local.repo.repo_org}-${local.repo.name}-${random_uuid.bucket_id.result}")
}

module "state" {
  source              = "../../../modules/bootstrap-state"
  region              = "eu-west-3"
  state_bucket_name   = "${local.repo.repo_org}-${local.repo.name}-tfstate"
  dynamodb_table_name = "${local.repo.repo_org}-${local.repo.name}-tfstate-locks"
  tags = {
    Project   = local.repo.name
    ManagedBy = "Terraform"
  }
}

module "github_actions" {
  source              = "../../.." # Path to the root of the module
  standalone          = true       # Do not use centralized actions
  repo                = local.repo
  github_organization = var.github_organization
  github_token        = var.github_token
  # github_app_id              = var.github_app_id
  # github_app_pem_file        = file(var.github_app_pem_file)
  # github_app_installation_id = var.github_app_installation_id
  environments = [
    {
      name                = "production"
      prevent_self_review = false
      can_admins_bypass   = true
      runner_group        = "ubuntu-latest"
      cache_bucket        = aws_s3_bucket.cache_bucket.bucket
      reviewers = {
        enforce_reviewers = false // activation requires billing plan
        teams             = ["terraform-approvers"]
      }
      deployment_branch_policy = {
        create_branch_protection = true
        restrict_branches        = false
      }
      state_config = {
        key_prefix     = "production"
        bucket         = "${local.repo.repo_org}-${local.repo.name}-tfstate"
        region         = "eu-west-3"
        dynamodb_table = "${local.repo.repo_org}-${local.repo.name}-tfstate-locks"
        set_backend    = true
      }
      vars = local.vars
      secrets = concat(local.secrets, [
        {
          "name"  = "CLOUDFLARE_API_TOKEN"
          "value" = var.cloudflare_api_token_prod
        },
      ])
    },
    {
      name                = "staging"
      prevent_self_review = false
      can_admins_bypass   = true
      runner_group        = "ubuntu-latest"
      cache_bucket        = aws_s3_bucket.cache_bucket.bucket
      reviewers = {
        enforce_reviewers = false // activation requires billing plan
        teams             = ["terraform-approvers"]
      }
      deployment_branch_policy = {
        create_branch_protection = true
        restrict_branches        = false
      }
      state_config = {
        key_prefix     = "staging"
        bucket         = "${local.repo.repo_org}-${local.repo.name}-tfstate"
        region         = "eu-west-3"
        dynamodb_table = "${local.repo.repo_org}-${local.repo.name}-tfstate-locks"
        set_backend    = true
      }
      vars = local.vars
      secrets = concat(local.secrets, [
        {
          "name"  = "CLOUDFLARE_API_TOKEN"
          "value" = var.cloudflare_api_token_stg
        }
      ])
    }
  ]
}
