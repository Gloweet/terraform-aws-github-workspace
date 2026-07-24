# https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team
# data "github_team" "github_codeowners_team" {
#   slug = var.github_codeowners_team
# }

# Create non-main default branch if specified
resource "github_branch" "branch" {
  count      = var.github_default_branch != "main" ? 1 : 0
  repository = local.github_repo.name
  branch     = var.github_default_branch
  depends_on = [
    github_repository.repo
  ]
}

# Set the default branch
resource "github_branch_default" "default_main_branch" {
  count      = var.github_default_branch != "main" ? 1 : 0
  repository = local.github_repo.name
  branch     = var.github_default_branch
  depends_on = [
    github_branch.branch
  ]
}

data "github_user" "pull_request_bypassers" {
  for_each = toset(var.pull_request_bypassers)
  username = each.value
}

locals {
  pull_request_bypassers = [for user in data.github_user.pull_request_bypassers : user.node_id]
}