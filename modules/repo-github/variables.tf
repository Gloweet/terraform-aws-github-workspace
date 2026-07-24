variable "name" {
  description = "Name of the repository"
  type        = string
}

variable "repo_org" {
  description = "GitHub organization name"
  type        = string
  default     = null
}

variable "github_codeowners_team" {
  default = "terraform-reviewers"
}

variable "github_repo_description" {
  description = "Repository description"
  type        = string
  default     = null
}

variable "github_repo_topics" {
  description = "Repository topics"
  type        = list(string)
  default     = []
}

variable "github_push_restrictions" {
  description = "List of team/user IDs with push access"
  type        = list(string)
  default     = []
}
variable "github_is_private" {
  description = "Make repository private"
  type        = bool
  default     = true
}
variable "github_auto_init" {
  description = "Initialize repository with README"
  type        = bool
  default     = true
}
variable "github_allow_merge_commit" {
  description = "Allow merge commits"
  type        = bool
  default     = false
}
variable "github_allow_squash_merge" {
  description = "Allow squash merging"
  type        = bool
  default     = true
}
variable "github_allow_rebase_merge" {
  description = "Allow rebase merging"
  type        = bool
  default     = false
}
variable "github_delete_branch_on_merge" {
  description = "Delete head branch after merge"
  type        = bool
  default     = true
}
variable "github_has_projects" {
  description = "Enable projects feature"
  type        = bool
  default     = true
}
variable "github_has_issues" {
  description = "Enable issues feature"
  type        = bool
  default     = false
}
variable "github_has_wiki" {
  description = "Enable wiki feature"
  type        = bool
  default     = true
}
variable "github_default_branch" {
  description = "Default branch name"
  type        = string
  default     = "main"
}
variable "github_required_approving_review_count" {
  description = "Number of approvals needed for pull requests"
  type        = number
  default     = 1
}
variable "github_require_code_owner_reviews" {
  description = "Require code owner review"
  type        = bool
  default     = true
}
variable "github_dismiss_stale_reviews" {
  description = "Dismiss stale pull request approvals"
  type        = bool
  default     = true
}
variable "github_enforce_admins_branch_protection" {
  description = "Enforce branch protection rules on administrators"
  type        = bool
  default     = true
}

variable "github_allow_auto_merge" {
  description = "Allow pull requests to be automatically merged"
  type        = bool
  default     = false
}

variable "github_has_downloads" {
  description = "Enable downloads feature"
  type        = bool
  default     = false
}

variable "additional_codeowners" {
  description = "Additional entries for CODEOWNERS file"
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Prefix to add to repository name"
  type        = string
  default     = null
}

variable "force_name" {
  description = "Keep exact repository name (no date suffix)"
  type        = bool
  default     = false
}

variable "github_org_teams" {
  description = "Organization teams configuration"
  type        = list(any)
  default     = null
}

variable "template_repo_org" {
  description = "Template repository organization"
  type        = string
  default     = null
}

variable "template_repo" {
  description = "Template repository name"
  type        = string
  default     = null
}

variable "is_template" {
  description = "Make this repository a template"
  type        = bool
  default     = false
}


variable "admin_teams" {
  description = "Teams to grant admin access"
  type        = list(string)
  default     = []
}


variable "required_status_checks" {
  description = "Required status checks for protected branches"
  type = object({
    contexts = list(string)
    strict   = optional(bool, false)
  })
  default = null
}

variable "archived" {
  description = "Archive this repository"
  type        = bool
  default     = false
}

variable "secrets" {
  description = "GitHub Actions secrets"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "vars" {
  description = "GitHub Actions variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "extra_files" {
  description = "Additional files to create in the repository"
  type = list(object({
    path    = string
    content = string
  }))
  default = []
}

variable "managed_extra_files" {
  description = "Additional files to manage in the repository"
  type = list(object({
    path    = string
    content = string
  }))
  default = []
}

variable "pull_request_bypassers" {
  description = "Users/teams that can bypass pull request requirements"
  type        = list(string)
  default     = []
}

variable "create_codeowners" {
  description = "Create CODEOWNERS file"
  type        = bool
  default     = true
}

variable "enforce_prs" {
  description = "Enforce pull request reviews"
  type        = bool
  default     = true
}

variable "collaborators" {
  description = "Map of collaborators and their permission levels"
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for perm in values(var.collaborators) : contains(["pull", "triage", "push", "maintain", "admin"], perm)])
    error_message = "Valid permissions are: pull, triage, push, maintain, admin"
  }
}


variable "archive_on_destroy" {
  description = "Archive repository instead of deleting on destroy"
  type        = bool
  default     = true
}

variable "vulnerability_alerts" {
  description = "Enable Dependabot alerts"
  type        = bool
  default     = false
}

variable "gitignore_template" {
  description = "Gitignore template to use"
  type        = string
  default     = null
}

variable "homepage_url" {
  description = "Repository homepage URL"
  type        = string
  default     = null
}

variable "create_repo" {
  description = "Whether to create a new repository or manage an existing one"
  type        = bool
  default     = true
}

variable "security_and_analysis" {
  description = "Security and analysis settings for the repository"
  type = object({
    advanced_security = optional(object({
      status = string
    }), { status = "disabled" })
    secret_scanning = optional(object({
      status = string
    }), { status = "disabled" })
    secret_scanning_push_protection = optional(object({
      status = string
    }), { status = "disabled" })
  })
  default = null
  validation {
    condition = var.security_and_analysis == null ? true : alltrue([
      try(contains(["enabled", "disabled"], var.security_and_analysis.advanced_security.status), true),
      try(contains(["enabled", "disabled"], var.security_and_analysis.secret_scanning.status), true),
      try(contains(["enabled", "disabled"], var.security_and_analysis.secret_scanning_push_protection.status), true)
    ])
    error_message = "Status values must be either 'enabled' or 'disabled'."
  }
}

variable "environments" {
  description = "List of GitHub environments to create for the repository"
  type = list(object({
    name = string
    reviewers = optional(object({
      teams = optional(list(string), [])
      users = optional(list(string), [])
    }), {})
    deployment_branch_policy = optional(object({
      protected_branches     = optional(bool, true)
      custom_branch_policies = optional(bool, false)
    }), {})
    secrets = optional(list(object({
      name  = string
      value = string
    })), [])
    vars = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "license_template" {
  description = "License template to use for the repository"
  type        = string
  default     = null
}

variable "github_has_discussions" {
  description = "Enable discussions feature"
  type        = bool
  default     = false
}

variable "github_merge_commit_title" {
  description = "Title for merge commits"
  type        = string
  default     = "MERGE_MESSAGE"
}

variable "github_merge_commit_message" {
  description = "Message for merge commits"
  type        = string
  default     = "PR_TITLE"
}

variable "github_squash_merge_commit_title" {
  description = "Title for squash merge commits"
  type        = string
  default     = "COMMIT_OR_PR_TITLE"
}

variable "github_squash_merge_commit_message" {
  description = "Message for squash merge commits"
  type        = string
  default     = "COMMIT_MESSAGES"
}

variable "github_allow_update_branch" {
  description = "Allow updating pull request branches"
  type        = bool
  default     = true
}

variable "pages_config" {
  description = "Configuration for GitHub Pages"
  type = object({
    branch = optional(string, "gh-pages")
    path   = optional(string, "/")
    cname  = optional(string)
  })
  default = null
}

variable "allow_unsigned_files" {
  description = "Whether to allow file management even when signed commits are required"
  type        = bool
  default     = false
}

variable "commit_author" {
  description = "The author name to use for file commits"
  type        = string
  default     = "Terraform"
}

variable "commit_email" {
  description = "The email to use for file commits"
  type        = string
  default     = "terraform@roknsound.com"
}

variable "require_signed_commits" {
  description = "Whether to require signed commits for the default branch"
  type        = bool
  default     = false
}

variable "require_last_push_approval" {
  description = "Require approval from the last pusher"
  type        = bool
  default     = false
}

variable "github_pro_enabled" {
  type        = bool
  default     = false
  description = "Is this a Github Pro Account? If not, then it's limited in feature set"
}

variable "deploy_keys" {
  description = "List of SSH deploy keys to add to the repository"
  type = list(object({
    title = string
    key   = optional(string, "")
    # The key is optional because it can be generated
    # by the module itself if create is set to true
    # and the key is not provided
    read_only = optional(bool, true)
    create    = optional(bool, false)
  }))
  default = []
}
