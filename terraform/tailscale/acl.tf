# https://registry.terraform.io/providers/tailscale/tailscale/latest/docs

resource "tailscale_acl" "acl" {
  acl = jsonencode({
    groups = {
      "group:admin" = ["nathanregner@gmail.com"]
    }
    tagOwners = {
      "tag:admin"  = ["group:admin"]
      "tag:server" = ["group:admin"]
      "tag:ssh"    = ["group:admin"]
    }

    acls = [
      {
        action = "accept"
        src    = ["group:admin", "tag:admin"]
        dst    = ["*:*"]
      },
      {
        action = "accept"
        src    = ["tag:server"]
        dst = [
          "tag:server:8080",  # atticd
          "tag:server:19999", # netdata
          "tag:server:7125",  # moonraker
        ]
      }
    ]

    ssh = [
      {
        action = "accept"
        src    = ["group:admin", "tag:admin"]
        dst    = ["tag:server", "tag:ssh"]
        users  = ["autogroup:nonroot", "root"]
      }
    ]
  })
}

