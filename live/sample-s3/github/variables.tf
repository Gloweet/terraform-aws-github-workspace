variable "aws_region" {
  type        = string
  description = "AWS Region (app-specific)"
  default     = "eu-west-3"
}
variable "github_organization" {
  type        = string
  description = "The GitHub organization name"
  sensitive   = false
}
variable "github_token" {
  type        = string
  description = "The GitHub token"
  sensitive   = true
}
variable "aws_role_arn" {
  type        = string
  description = "The AWS role ARN"
  sensitive   = true
}
variable "slack_webhook_url" {
  type        = string
  description = "The Slack webhook URL"
  sensitive   = false
}

variable "terraform_version" {
  type        = string
  description = "The version of Terraform to use"
}

variable "org_token" {
  description = "GitHub personal access token with organization permissions"
  type        = string
  sensitive   = true
}
