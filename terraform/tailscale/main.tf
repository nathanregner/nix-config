terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/tailscale"
    region = "us-west-2"
  }
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.13.10"
    }
  }
}

provider "tailscale" {
  oauth_client_id     = file("~/run/secrets/tailscale/client_id")
  oauth_client_secret = file("~/run/secrets/tailscale/client_secret")
}

resource "tailscale_tailnet_key" "server" {
  ephemeral     = false
  expiry        = null
  preauthorized = true
  reusable      = true
  tags          = ["tag:server"]
}

resource "tailscale_tailnet_key" "builder" {
  ephemeral     = true
  expiry        = null
  preauthorized = true
  reusable      = true
  tags          = ["tag:server"]
}

output "server_key" {
  value     = tailscale_tailnet_key.server.key
  sensitive = true
}

output "builder_key" {
  value     = tailscale_tailnet_key.builder.key
  sensitive = true
}

