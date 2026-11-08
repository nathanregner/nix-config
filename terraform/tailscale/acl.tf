# https://registry.terraform.io/providers/tailscale/tailscale/latest/docs
# https://tailscale.com/kb/1337/acl-syntax

locals {
  globals = jsondecode(file("../../globals.json"))
}

resource "tailscale_acl" "acl" {
  acl = jsonencode({
    groups = {
      "group:admin" = [
        "nathanregner@gmail.com",
      ]
    }
    tagOwners = {
      "tag:admin"   = ["nathanregner@gmail.com"]
      "tag:server"  = ["nathanregner@gmail.com"]
      "tag:ssh"     = ["nathanregner@gmail.com"]
      "tag:hydra"   = ["nathanregner@gmail.com"]
      "tag:builder" = ["nathanregner@gmail.com"]
    }
    hosts = { for hostname, d in local.devices : hostname => d.addresses[0] }

    # https://tailscale.com/kb/1337/acl-syntax#acls
    acls = concat(
      [
        {
          action = "accept"
          src    = ["group:admin", "tag:admin"]
          dst    = ["*:*"]
        },
        {
          action = "accept"
          src    = ["group:admin", "tag:admin", "sagittarius"]
          dst    = ["tag:builder:22"]
        },
        {
          action = "accept"
          src    = ["tag:server"]
          dst    = ["sagittarius:${local.globals.services.hydra.port}"]
        },
        {
          # hydra builders dial the queue runner over gRPC
          action = "accept"
          src    = ["tag:builder"]
          dst    = ["sagittarius:${local.globals.services.hydra.grpcPort}"]
        },
        {
          action = "accept"
          src    = ["tag:server"]
          dst    = ["sagittarius:${local.globals.services.restic-server.port}"]
        }
      ],
      [
        for exporter in local.globals.services.prometheus :
        {
          action = "accept"
          src    = ["sagittarius"]
          dst    = ["*:${exporter.port}"]
        }
      ],
    )

    # https://tailscale.com/kb/1337/acl-syntax#ssh
    ssh = [
      {
        action = "accept"
        src    = ["group:admin", "tag:admin"]
        dst    = ["tag:builder", "tag:server", "tag:admin"]
        users  = ["autogroup:nonroot", "root"]
      },
      {
        action = "accept"
        src    = ["group:admin", "tag:admin", "tag:hydra"]
        dst    = ["tag:builder"]
        users  = ["autogroup:nonroot", "root"]
      },
    ]

    # https://tailscale.com/kb/1337/acl-syntax#sshtests
    # tests referencing hosts that aren't registered are dropped
    sshTests = [
      for test in [
        {
          src    = "sagittarius"
          dst    = ["enceladus"]
          accept = ["nregner"]
        },
        {
          src    = "sagittarius"
          dst    = ["enceladus-linux-vm"]
          accept = ["builder"]
        },
        {
          src    = "enceladus"
          dst    = ["enceladus-linux-vm"]
          accept = ["nregner"]
        },
        {
          src    = "sagittarius"
          dst    = ["iapetus"]
          accept = ["nregner"]
        },
      ] : test
      if alltrue([for host in concat([test.src], test.dst) : contains(keys(local.devices), host)])
    ]
  })
}

