terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/dns"
    region = "us-west-2"
  }
}

data "aws_route53_zone" "nregner_net" {
  name = "nregner.net"
}

locals {
  users = {
    voron  = { subdomain = "voron" },
    kraken = { subdomain = "kraken-*" },
  }
}

module "iam" {
  source    = "./iam"
  for_each  = local.users
  username  = each.key
  subdomain = each.value.subdomain
}

output "aws_env" {
  value     = { for username, iam in module.iam : username => jsonencode(iam.aws_env) }
  sensitive = true
}
