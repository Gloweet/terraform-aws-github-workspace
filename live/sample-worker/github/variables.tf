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
variable "cloudflare_account_id" {
  type        = string
  description = "The Cloudflare account ID"
}
variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with Workers Scripts:Edit"
  sensitive   = true
}
variable "worker_name" {
  type        = string
  description = "Cloudflare Worker name (must be unique per environment)"
  default     = "sample-worker"
}
variable "worker_route" {
  type        = string
  description = "Optional custom domain for the Worker, e.g. app.example.com"
  default     = ""
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
