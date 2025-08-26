variable "create_oidc_provider" {
  type    = bool
  default = false
}

variable "oidc_url" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "aws_region" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type    = string
  default = null
}

variable "allow_all_repos" {
  type    = bool
  default = false
}

variable "role_name" {
  type    = string
  default = "github-actions-oidc"
}

variable "extra_policy_json" {
  description = "Optional IAM policy JSON string to attach to the role"
  type        = string
  default     = null
}

variable "github_oidc_thumbprints" {
  type    = list(string)
  default = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
