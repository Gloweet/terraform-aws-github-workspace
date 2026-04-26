provider "github" {
  owner = var.github_organization
  token = var.github_token
}

provider "aws" {
  region = "eu-west-3"
}
