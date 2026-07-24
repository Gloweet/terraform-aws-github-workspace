locals {
  branch_protection_rules = merge(
    var.enforce_prs == true ? {
      main = {
        pattern                 = var.github_default_branch
        enforce_admins          = var.github_enforce_admins_branch_protection
        allows_deletions        = false
        require_signed_commits  = var.require_signed_commits
        required_linear_history = true
        required_status_checks  = var.required_status_checks
        required_pull_request_reviews = {
          dismiss_stale_reviews           = var.github_dismiss_stale_reviews
          require_code_owner_reviews      = var.github_require_code_owner_reviews
          required_approving_review_count = var.github_required_approving_review_count
          pull_request_bypassers          = var.pull_request_bypassers
        }
      }
    } : {}
  )
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection
resource "github_branch_protection" "protection" {
  for_each = {
    for k, v in local.branch_protection_rules : k => v if var.enforce_prs && (!var.github_is_private || var.github_pro_enabled)
  }

  repository_id = var.create_repo ? github_repository.repo[0].node_id : data.github_repository.existing[0].node_id
  pattern       = each.key

  enforce_admins          = var.github_enforce_admins_branch_protection
  required_linear_history = true
  allows_force_pushes     = false
  allows_deletions        = false
  require_signed_commits  = var.require_signed_commits

  required_pull_request_reviews {
    required_approving_review_count = var.github_required_approving_review_count
    dismiss_stale_reviews           = var.github_dismiss_stale_reviews
    require_code_owner_reviews      = var.github_require_code_owner_reviews
    require_last_push_approval      = var.require_last_push_approval
  }

  dynamic "required_status_checks" {
    for_each = var.required_status_checks != null ? ["true"] : []
    content {
      strict   = try(var.required_status_checks.strict, true)
      contexts = try(var.required_status_checks.contexts, [])
    }
  }

  depends_on = [
    github_repository.repo,
    github_branch.branch,
    github_branch_default.default_main_branch,
    github_repository_file.extra_files,
    github_repository_file.codeowners,
    github_repository_file.managed_extra_files
  ]
}