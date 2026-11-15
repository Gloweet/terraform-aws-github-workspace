data "aws_caller_identity" "current" {}

locals {
  aws_region          = "eu-west-3"
  github_organization = "Gloweet"
  repo_name           = "sample-s3"
}

module "aws-federation-oidc" {
  source               = "../../../modules/aws-federation-oidc"
  aws_region           = local.aws_region
  github_org           = local.github_organization
  github_repo          = local.repo_name
  allow_all_repos      = false
  create_oidc_provider = false
  # Role names are unique per AWS account: always scope them per app.
  role_name = "github-actions-${local.repo_name}-production"

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
        Action = ["cloudfront:CreateInvalidation"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = local.repo_name
          }
        }
        Resource = "*"
      }
      # The app workflow also needs write access to the site buckets it syncs to:
      #   s3://<environment>-<repo_name>-primary   (and -failover when IS_RELEASE = "true")
      # Add those statements here once the buckets exist.
    ]
  })
}

output "role_arn" {
  value = module.aws-federation-oidc.role_arn
}
