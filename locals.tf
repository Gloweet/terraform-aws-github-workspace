
locals {
  environments = { for env in var.environments : env.name => env }
  # `runner_group` accepts either a single label ("ubuntu-latest") or a list of
  # labels (["self-hosted", "linux", "x64"]). Normalize to a list so templates can
  # render `runs-on` with jsonencode().
  runs_on = {
    for env in var.environments : env.name => (
      env.runner_group == null ? ["self-hosted"] :
      can(tolist(env.runner_group)) ? tolist(env.runner_group) : [tostring(env.runner_group)]
    )
  }
  environment_reviewers = {
    for env in var.environments : env.name => lookup(module.context, env.name).review_users
  }
  environment_teams = {
    for env in var.environments : env.name => lookup(module.context, env.name).review_teams
  }
}
