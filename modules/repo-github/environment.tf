data "github_team" "environment_teams" {
  for_each = toset(flatten([
    for env in var.environments :
    try(coalesce(env.reviewers.teams, []), [])
  ]))
  slug = each.value # Look up teams by slug (name) instead of ID
}

data "github_user" "environment_users" {
  for_each = toset(flatten([
    for env in var.environments :
    try(coalesce(env.reviewers.users, []), [])
  ]))
  username = each.value
}

resource "github_repository_environment" "environments" {
  for_each = { for env in var.environments : env.name => env }

  environment = each.value.name
  repository  = github_repository.repo[0].name
  reviewers {
    teams = [for team_slug in try(each.value.reviewers.teams, []) : data.github_team.environment_teams[team_slug].id]
    users = [for username in try(each.value.reviewers.users, []) : data.github_user.environment_users[username].id]
  }
  deployment_branch_policy {
    protected_branches     = try(each.value.deployment_branch_policy.protected_branches, true)
    custom_branch_policies = try(each.value.deployment_branch_policy.custom_branch_policies, false)
  }
}

resource "github_actions_environment_secret" "environment_secrets" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for secret in coalesce(env.secrets, []) : {
          env_name = env.name
          name     = secret.name
          value    = secret.value
        }
      ]
    ]) : "${pair.env_name}.${pair.name}" => pair
  }

  repository      = github_repository.repo[0].name
  environment     = each.value.env_name
  secret_name     = each.value.name
  plaintext_value = each.value.value

  depends_on = [github_repository_environment.environments]
}

resource "github_actions_environment_variable" "environment_variables" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for _var in coalesce(env.vars, []) : {
          env_name = env.name
          name     = _var.name
          value    = _var.value
        }
      ]
    ]) : "${pair.env_name}.${pair.name}" => pair
  }

  repository    = github_repository.repo[0].name
  environment   = each.value.env_name
  variable_name = each.value.name
  value         = each.value.value

  depends_on = [github_repository_environment.environments]
}