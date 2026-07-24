# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
data "github_organization_teams" "root_teams" {
  count           = var.github_org_teams == null && var.repo_org != null ? 1 : 0
  root_teams_only = false
}

data "github_team" "admin_teams" {
  for_each = toset(var.admin_teams)
  slug     = each.value
}

locals {
  github_org_teams = var.github_org_teams == null ? try(data.github_organization_teams.root_teams[0].teams, []) : var.github_org_teams
  github_teams     = { for obj in local.github_org_teams : "${obj.slug}" => obj.id }
  team_repository_permissions = {
    "pull"     = "read"
    "triage"   = "triage"
    "push"     = "write"
    "maintain" = "maintain"
    "admin"    = "admin"
  }
}

resource "github_team_repository" "admin" {
  for_each   = { for team in var.admin_teams : team => data.github_team.admin_teams[team].id }
  team_id    = each.value
  repository = var.create_repo ? github_repository.repo[0].name : data.github_repository.existing[0].name
  permission = "admin"

  lifecycle {
    ignore_changes = [
      team_id
    ]
  }
}
