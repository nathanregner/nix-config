terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/github"
    region = "us-west-2"
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {}

resource "github_repository_webhook" "nix_config" {
  repository = "nix-config"
  events     = ["push"]
  configuration {
    url          = "https://github.nregner.net/"
    content_type = "json"
    insecure_ssl = false
    secret       = var.webhook_secret
  }
  active = false
}

variable "webhook_secret" {
  type = string
}
