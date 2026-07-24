locals {
  # Permission mapping for collaborator roles
  permission_map = {
    "pull"     = "read"
    "triage"   = "triage"
    "push"     = "write"
    "maintain" = "maintain"
    "admin"    = "admin"
  }
}

data "github_user" "collaborators" {
  for_each = var.collaborators
  username = each.key
}

# Add a collaborator to a repository
resource "github_repository_collaborator" "collaborators" {
  for_each   = tomap(var.collaborators)
  repository = var.create_repo ? github_repository.repo[0].name : data.github_repository.existing[0].name
  username   = each.key
  permission = local.permission_map[each.value]

  depends_on = [
    data.github_user.collaborators
  ]
}
