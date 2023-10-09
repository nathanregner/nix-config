terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/restic"
    region = "us-west-2"
  }
}

module "s3" {
  source = "./s3"
  for_each = toset([
    "sagittarius",
    "voron",
  ])
  bucket_name = "nregner-restic-${each.key}"
  username    = each.key
}

locals {
  secrets = {
    s3_env = { for machine, s3 in module.s3 : machine => s3.env }
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
