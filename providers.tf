terraform {
  required_version = "~> 1.1.3"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.19.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.71"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.7.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile_name
}
