# OIDC provider
## Sub conditions
locals {
  sub_patterns = (
    var.allow_all_repos
    ? ["repo:${var.github_org}/*"]
    : [
      "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*",
      "repo:${var.github_org}/${var.github_repo}:ref:refs/tags/*",
      "repo:${var.github_org}/${var.github_repo}:ref:refs/pull/*"
    ]
  )
}

## Existing provider (use data source)
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = var.oidc_url
}

## New provider (create resource)
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = var.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

# Pick the correct ARN (either from data or resource)
locals {
  github_oidc_provider_arn = (var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
  : data.aws_iam_openid_connect_provider.github[0].arn)
}

# IAM Role
resource "aws_iam_role" "github_actions" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = local.github_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.sub_patterns
          }
        }
      }
    ]
  })
}


# Attach extra permissions (optional)
resource "aws_iam_role_policy" "extra" {
  count = var.extra_policy_json == null ? 0 : 1

  role   = aws_iam_role.github_actions.id
  policy = var.extra_policy_json
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
