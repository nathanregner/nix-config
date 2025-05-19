terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/notifications"
    region = "us-west-2"
  }
}

resource "aws_route53_zone" "primary" {
  name = "nregner.net"
}

resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "*.nregner.net"
  type    = "CNAME"
  ttl     = 900
  records = ["nregner.net"]
}

resource "aws_route53domains_registered_domain" "primary" {
  domain_name = "nregner.net"
  dynamic "name_server" {
    for_each = aws_route53_zone.primary.name_servers
    content {
      name = name_server.value
    }
  }
}

module "acme" {
  source      = "./acme"
  hosted_zone = aws_route53_zone.primary
  username    = "sagittarius"
}

module "ddns" {
  source = "./ddns"
  for_each = {
    sagittarius = { subdomain = null }
    voron       = { subdomain = "voron" }
    print-farm  = { subdomain = "*.print" }
  }
  hosted_zone = aws_route53_zone.primary
  username    = each.key
  subdomain   = each.value.subdomain
}

locals {
  secrets = {
    acme = { sagittarius = module.acme.env }
    ddns = { for machine, ddns in module.ddns : machine => ddns.env }
  }
  machines = toset(flatten([for _, machines in local.secrets : keys(machines)]))
}

output "secrets" {
  value = {
    for machine in local.machines :
    machine =>
    { for secret, machines in local.secrets :
      secret => machines[machine]
      if contains(keys(machines), machine)
    }
  }
  sensitive = true
}
