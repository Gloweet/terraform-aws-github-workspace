locals {
  repo_name = var.force_name ? var.name : "${var.name}-${formatdate("YYYYMMDD", timestamp())}"

  # Safe access to repo and existing resources
  github_repo = var.create_repo && length(github_repository.repo) > 0 ? github_repository.repo[0] : (
    length(data.github_repository.existing) > 0 ? data.github_repository.existing[0] : null
  )

  validate_merge_options = (
    var.github_allow_merge_commit ||
    var.github_allow_squash_merge ||
    var.github_allow_rebase_merge
  ) ? null : file("ERROR: At least one merge option must be enabled")
}

resource "github_repository" "repo" {
  count                       = var.create_repo ? 1 : 0
  name                        = local.repo_name
  description                 = var.github_repo_description
  visibility                  = var.github_is_private ? "private" : "public"
  has_issues                  = var.github_has_issues
  has_projects                = var.github_has_projects
  has_wiki                    = var.github_has_wiki
  has_downloads               = var.github_has_downloads
  auto_init                   = var.github_auto_init
  archive_on_destroy          = var.archive_on_destroy
  archived                    = var.archived
  vulnerability_alerts        = var.vulnerability_alerts
  topics                      = var.github_repo_topics
  homepage_url                = var.homepage_url
  gitignore_template          = var.gitignore_template
  license_template            = var.license_template
  is_template                 = var.is_template
  has_discussions             = try(var.github_has_discussions, false)
  merge_commit_title          = try(var.github_merge_commit_title, "MERGE_MESSAGE")
  merge_commit_message        = try(var.github_merge_commit_message, "PR_TITLE")
  squash_merge_commit_title   = try(var.github_squash_merge_commit_title, "COMMIT_OR_PR_TITLE")
  squash_merge_commit_message = try(var.github_squash_merge_commit_message, "COMMIT_MESSAGES")
  allow_update_branch         = try(var.github_allow_update_branch, true)

  allow_merge_commit     = var.github_allow_merge_commit
  allow_squash_merge     = var.github_allow_squash_merge
  allow_rebase_merge     = var.github_allow_rebase_merge
  allow_auto_merge       = var.github_allow_auto_merge
  delete_branch_on_merge = var.github_delete_branch_on_merge

  dynamic "template" {
    for_each = var.template_repo == null ? [] : ["*"]
    content {
      owner      = var.template_repo_org
      repository = var.template_repo
    }
  }

  dynamic "security_and_analysis" {
    for_each = var.security_and_analysis == null ? [] : ["*"]
    content {
      dynamic "advanced_security" {
        for_each = try(var.security_and_analysis.advanced_security, null) == null ? [] : ["*"]
        content {
          status = var.security_and_analysis.advanced_security.status
        }
      }
      dynamic "secret_scanning" {
        for_each = try(var.security_and_analysis.secret_scanning, null) == null ? [] : ["*"]
        content {
          status = var.security_and_analysis.secret_scanning.status
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = try(var.security_and_analysis.secret_scanning_push_protection, null) == null ? [] : ["*"]
        content {
          status = var.security_and_analysis.secret_scanning_push_protection.status
        }
      }
    }
  }

  dynamic "pages" {
    for_each = var.pages_config == null ? [] : ["true"]
    content {
      source {
        branch = try(var.pages_config.branch, "gh-pages")
        path   = try(var.pages_config.path, "/")
      }
      cname = try(var.pages_config.cname, null)
    }
  }

  lifecycle {
    ignore_changes = [
      auto_init,
      template
    ]
  }
}
