resource "github_actions_secret" "secret" {
  for_each        = tomap({ for secret in var.secrets : secret.name => secret.value })
  repository      = var.create_repo ? github_repository.repo[0].name : data.github_repository.existing[0].name
  secret_name     = each.key
  plaintext_value = each.value
  depends_on      = [github_repository.repo, data.github_repository.existing]
}

resource "github_actions_variable" "variable" {
  for_each      = tomap({ for _var in var.vars : _var.name => _var.value })
  repository    = var.create_repo ? github_repository.repo[0].name : data.github_repository.existing[0].name
  variable_name = each.key
  value         = each.value
  depends_on    = [github_repository.repo, data.github_repository.existing]
}
