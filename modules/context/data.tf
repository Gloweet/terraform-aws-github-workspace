data "github_user" "all_reviewers" {
  for_each = toset(var.environment.reviewers.users)
  username = each.value
}

locals {
  org_teams = { for team in var.teams : team.name => team }
}
