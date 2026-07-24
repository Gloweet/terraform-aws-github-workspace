locals {
  repo = {
    name        = "tolgee-platform"
    description = "Gloweet fork of Tolgee Platform, with our own ECR + CI/CD"
    create_repo = true
    repo_org    = "Gloweet"
    is_private  = true
    working_dir = "terraform"

    deploy_target  = "ecr"
    ecr_image_name = "tolgee-platform"
  }
  secrets = [
    {
      "name"  = "AWS_ROLE_ARN"
      "value" = var.aws_role_arn
    },
    {
      "name"  = "ORG_TOKEN"
      "value" = var.org_token
    }
  ]
  vars = [
    {
      "name"  = "TERRAFORM_VERSION"
      "value" = var.terraform_version
    },
    {
      "name"  = "AWS_REGION"
      "value" = var.aws_region
    },
    {
      "name"  = "ECR_REPOSITORY_URL"
      "value" = var.ecr_repository_url
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
      runner_group        = "ubuntu-latest"
      cache_bucket        = aws_s3_bucket.cache_bucket.bucket
      reviewers = {
        enforce_reviewers = false
        teams             = ["terraform-approvers"]
      }
      deployment_branch_policy = {
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
    }
  ]
}
