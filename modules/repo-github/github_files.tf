locals {
  # Process files only if commit signing is not required or if explicitly allowed
  should_manage_files = !try(local.github_repo.require_signed_commits, false) || var.allow_unsigned_files
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "codeowners" {
  count = var.create_codeowners && local.should_manage_files ? 1 : 0

  repository          = local.github_repo.name
  branch              = var.github_default_branch
  file                = "CODEOWNERS"
  content             = templatefile("${path.module}/templates/CODEOWNERS", { codeowners = local.codeowners })
  commit_message      = "Update CODEOWNERS file"
  commit_author       = var.commit_author
  commit_email        = var.commit_email
  overwrite_on_create = true
  depends_on = [
    github_repository.repo
  ]
  lifecycle {
    ignore_changes = [
      content,
      branch
    ]
  }
}

locals {
  lookup_sha = var.template_repo == null ? 0 : var.template_repo_org == var.repo_org ? 1 : 0
}

data "github_repository" "template_repo" {
  count     = local.lookup_sha
  full_name = "${var.template_repo_org == null ? "" : var.template_repo_org}/${var.template_repo == null ? "" : var.template_repo}"
}

data "github_ref" "ref" {
  count      = local.lookup_sha
  owner      = var.template_repo_org
  repository = var.template_repo
  ref        = "heads/${local.lookup_sha > 0 && length(data.github_repository.template_repo) > 0 ? coalesce(lookup(data.github_repository.template_repo[0], "default_branch", "main"), "main") : "main"}"
}

locals {
  extra_files = concat(
    var.extra_files,
    local.lookup_sha == 1 ? [
      {
        path    = ".TEMPLATE_SHA",
        content = local.lookup_sha == 1 && length(data.github_ref.ref) > 0 ? data.github_ref.ref[0].sha : ""
      }
    ] : []
  )
  repository_name = var.create_repo ? local.github_repo.name : var.name
}

resource "github_repository_file" "extra_files" {
  for_each = local.should_manage_files ? tomap({ for file in local.extra_files : "${element(split("/", file.path), length(split("/", file.path)) - 1)}" => file }) : {}

  repository          = local.github_repo.name
  branch              = var.github_default_branch
  file                = each.value.path
  content             = each.value.content
  commit_message      = "Update ${each.value.path}"
  commit_author       = var.commit_author
  commit_email        = var.commit_email
  overwrite_on_create = true
  depends_on = [
    github_repository.repo
  ]
  lifecycle {
    ignore_changes = [
      content,
      branch
    ]
  }
}

resource "github_repository_file" "managed_extra_files" {
  for_each = local.should_manage_files ? tomap({ for file in var.managed_extra_files : "${element(split("/", file.path), length(split("/", file.path)) - 1)}" => file }) : {}

  repository          = local.github_repo.name
  branch              = var.github_default_branch
  file                = each.value.path
  content             = each.value.content
  commit_message      = "Update ${each.value.path}"
  commit_author       = var.commit_author
  commit_email        = var.commit_email
  overwrite_on_create = true
  depends_on = [
    github_repository.repo
  ]
  lifecycle {
    ignore_changes = [
      branch
    ]
  }
}
