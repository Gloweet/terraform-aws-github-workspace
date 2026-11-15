variable "environment" {
  type = object({
    # Name of the environment
    name                = string
    prevent_self_review = optional(bool, false)  # Flag to prevent self review
    wait_timer          = optional(number, null) # Wait timer for review
    # Reviewers configuration
    can_admins_bypass = optional(bool, true) # Flag to allow admins to bypass
    # Runner labels used for `runs-on`: either a single label ("ubuntu-latest") or a
    # list (["self-hosted", "linux", "x64"]).
    runner_group = optional(any, "self-hosted")
    reviewers = optional(object({
      users             = optional(list(string), []) # List of user reviewers
      teams             = optional(list(string), []) # List of team reviewers
      enforce_reviewers = optional(bool, false)      # Flag to enforce reviewers
      }), {
      users = []
      teams = []
    })
    cache_bucket = string
    # Deployment branch policy configuration
    deployment_branch_policy = optional(object({
      branch                   = optional(string)      # Branch name
      branch_pattern           = optional(string)      # Branch pattern
      create_branch            = optional(bool, false) # Flag to create branch
      create_branch_protection = optional(bool, true)  # Flag to create branch protection
      protected_branches       = optional(bool, true)  # Flag to protect branches
      custom_branch_policies   = optional(bool, false) # Flag to enable custom branch policies
      enforce_admins           = optional(bool, false) # Flag to enforce admin rules
      restrict_branches        = optional(bool, true)  # Flag to create policy
      required_status_checks = optional(object({
        strict   = optional(bool, true) # Flag to enforce strict status checks
        contexts = list(string)         # List of status check contexts
        }), {
        strict   = false
        contexts = []
      })
      required_pull_request_reviews = optional(object({
        dismiss_stale_reviews           = optional(bool, true) # Flag to dismiss stale reviews
        require_code_owner_reviews      = optional(bool, true) # Flag to require code owner reviews
        required_approving_review_count = optional(number, 1)  # Number of required approving reviews
        }), {
        dismiss_stale_reviews           = true
        require_code_owner_reviews      = true
        required_approving_review_count = 1
      })
      }), {
      branch                 = "main"
      create_branch          = false
      protected_branches     = true
      custom_branch_policies = false
    })

    # State configuration for Terraform
    state_config = optional(object({
      bucket         = optional(string)      # S3 bucket name
      key_prefix     = optional(string)      # Key prefix for the state file
      region         = optional(string)      # AWS region
      dynamodb_table = optional(string)      # DynamoDB table for state locking
      set_backend    = optional(bool, false) # Flag to set backend
      }), null
    )

    # Secrets for GitHub Actions
    secrets = optional(list(object({
      name  = string # Secret name
      value = string # Secret value
    })), [])

    # Variables for GitHub Actions
    vars = optional(list(object({
      name  = string # Variable name
      value = string # Variable value
    })), [])
  })
}

variable "state_config" {
  type = object({
    bucket         = optional(string, "inf-tfstate-us-gov-west-1-229685449397")
    key            = optional(string, "terraform.tfstate")
    region         = optional(string, "us-gov-west-1")
    dynamodb_table = optional(string, "tf_remote_state")
    set_backend    = optional(bool, false)
    key_prefix     = optional(string, "terraform-state-files")
  })
  description = "Configuration for Terraform state storage"

  default = {}

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.state_config.bucket))
    error_message = "Bucket name must be between 3 and 63 characters, and can contain only lowercase letters, numbers, dots, and hyphens."
  }
  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|af|me|us-gov)-(north|south|east|west|central|northeast|southeast|southwest|northwest|central)-[0-9]$", var.state_config.region))
    error_message = "Region must be a valid AWS region, e.g., us-east-1, eu-west-3, us-gov-west-1."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.state_config.dynamodb_table))
    error_message = "DynamoDB table name must be between 3 and 255 characters, and can contain only letters, numbers, underscores, dots, and hyphens."
  }
}

variable "repo" {
  type = object({
    collaborators = optional(map(string), {})
    create_repo   = optional(bool, true)
    description   = optional(string, "")
    enforce_prs   = optional(bool, true)
    codeowners    = optional(string, "")
    vars = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name  = string
      value = string
    })), [])
    admin_teams            = optional(list(string), [])
    create_codeowners      = optional(bool, false)
    pull_request_bypassers = optional(list(string), [])
    github_organization_teams = optional(list(object({
      slug = string
      id   = string
    })), [])
    is_private         = optional(bool, false)
    is_template        = optional(bool, false)
    template_repo_org  = optional(string, null)
    template_repo      = optional(string, null)
    name               = string
    repo_org           = string
    repo_topics        = optional(list(string), [])
    archive_on_destroy = optional(bool, false)
    extra_files = optional(list(object({
      path    = string,
      content = string
    })), [])
    managed_extra_files = optional(list(object({
      path    = string,
      content = string
    })), [])
  })
  description = "Configuration for the GitHub repository"
}

variable "teams" {}
