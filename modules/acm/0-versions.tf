# https://github.com/cloudflare/terraform-provider-cloudflare
terraform {
  required_version = "~> 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.62"
    }
  }
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
