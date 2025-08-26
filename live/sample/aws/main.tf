data "aws_caller_identity" "current" {}

locals {
  aws_region          = "eu-west-3"
  github_organization = "your_organization"
  repo_name           = "sample-app"
}

module "aws-federation-oidc" {
  source               = "../../../modules/aws-federation-oidc"
  aws_region           = local.aws_region
  github_org           = local.github_organization
  github_repo          = local.repo_name
  allow_all_repos      = false
  create_oidc_provider = false
  role_name            = "github-actions-production"

  # Attach environment-specific policies
  extra_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${local.github_organization}-${local.repo_name}-tfstate"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${local.github_organization}-${local.repo_name}-tfstate/*"
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
        Resource = "arn:aws:dynamodb:eu-west-3:${data.aws_caller_identity.current.account_id}:table/${local.github_organization}-${local.repo_name}-tfstate-locks"
      },
      # Project-specific policies
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:ResourceTag/Project" = local.repo_name
          }
        }
      }
    ]
  })
}

output "role_arn" {
  value = module.aws-federation-oidc.role_arn
}
