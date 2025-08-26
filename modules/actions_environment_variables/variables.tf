variable "secrets" {
  type = list(object({
    name  = string,
    value = string
  }))
  default     = []
  description = "Github Action Secrets"
  validation {
    condition     = length(var.secrets) >= 0
    error_message = "Secrets must be a list of objects with name and value."
  }
}

variable "vars" {
  type = list(object({
    name  = string,
    value = string
  }))
  default     = []
  description = "Github Action Vars"
  validation {
    condition     = length(var.vars) >= 0
    error_message = "Vars must be a list of objects with name and value."
  }
}

variable "environment" {
  type        = string
  description = "The environment name"
  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment name must not be empty."
  }
}

variable "repo_name" {
  type        = string
  description = "The name of the repository"
  validation {
    condition     = length(var.repo_name) > 0
    error_message = "Repository name must not be empty."
  }
}

variable "repo_org" {
  type        = string
  nullable    = true
  description = "The organization of the repository"
  validation {
    condition     = length(var.repo_org) > 0
    error_message = "Repository organization must not be empty."
  }
}
