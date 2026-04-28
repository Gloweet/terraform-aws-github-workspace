data "aws_caller_identity" "current" {}

locals {
  aws_region          = "eu-west-3"
  github_organization = "Gloweet"
  repo_name           = "headlamp-plugins"
  image_name          = var.image_name
}

variable "image_name" {
  description = "Name of the ECR repository and Docker image"
  type        = string
  default     = "headlamp-plugins"
}

module "aws-federation-oidc" {
  source               = "../../../modules/aws-federation-oidc"
  aws_region           = local.aws_region
  github_org           = local.github_organization
  github_repo          = local.repo_name
  allow_all_repos      = false
  create_oidc_provider = false
  role_name            = "github-actions-production"

  extra_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${lower(local.github_organization)}-${local.repo_name}-tfstate"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${lower(local.github_organization)}-${local.repo_name}-tfstate/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${local.aws_region}:${data.aws_caller_identity.current.account_id}:table/${lower(local.github_organization)}-${local.repo_name}-tfstate-locks"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = local.repo_name
          }
        }
        Resource = "*"
      },
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.image_name}"
      }
    ]
  })
}

resource "aws_ecr_repository" "this" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "role_arn" {
  value = module.aws-federation-oidc.role_arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}
