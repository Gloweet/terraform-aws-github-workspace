resource "github_actions_environment_secret" "secret" {
  for_each        = tomap({ for secret in var.secrets : secret.name => secret.value })
  secret_name     = each.key
  plaintext_value = each.value
  environment     = var.environment
  repository      = var.repo_name
}

resource "github_actions_environment_variable" "variable" {
  for_each      = tomap({ for _var in var.vars : _var.name => _var.value })
  environment   = var.environment
  variable_name = each.key
  value         = each.value
  repository    = var.repo_name
}
