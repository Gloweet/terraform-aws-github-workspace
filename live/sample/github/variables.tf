variable "aws_region" {
  type        = string
  description = "AWS Region (app-specifc)"
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
# variable "github_app_id" {
#   type        = string
#   description = "The GitHub App ID"
#   sensitive   = true
# }
# variable "github_app_installation_id" {
#   type        = string
#   description = "This is the ID of the GitHub App installation"
#   sensitive   = true
# }
# variable "github_app_pem_file" {
#   type        = string
#   description = "This is the path to the GitHub App private key PEM file."
#   sensitive   = true
# }
variable "terraform_version" {
  type        = string
  description = "The version of Terraform to use"
}

variable "org_token" {
  description = "GitHub personal access token with organization permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token_prod" {
  description = "Cloudflare API token for production environment"
  type        = string
  sensitive   = true
  default     = "myTokenProd"
}

variable "cloudflare_api_token_stg" {
  description = "Cloudflare API token for staging environment"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token_dev" {
  description = "Cloudflare API token for development environment"
  type        = string
  sensitive   = true
}
