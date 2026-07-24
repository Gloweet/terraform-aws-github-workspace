// Generate SSH keys when create is true
resource "tls_private_key" "deploy_key" {
  for_each = {
    for k, v in var.deploy_keys : k => v
    if v.create == true
  }

  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create GitHub deploy keys for all entries
resource "github_repository_deploy_key" "deploy_key" {
  for_each = {
    for k, v in var.deploy_keys : k => v
  }

  title      = each.value.title
  repository = local.github_repo.name
  key        = each.value.create ? tls_private_key.deploy_key[each.key].public_key_openssh : each.value.key
  read_only  = each.value.read_only

  depends_on = [
    github_repository.repo,
    data.github_repository.existing
  ]
}
