locals {
  # hostname => tags. Devices that aren't currently registered in the tailnet are skipped.
  device_tags = {
    iapetus            = ["tag:admin", "tag:builder"]
    sagittarius        = ["tag:hydra", "tag:server"]
    enceladus          = ["tag:admin", "tag:builder"]
    enceladus-linux-vm = ["tag:builder"]
  }

  devices_by_hostname = {
    for d in data.tailscale_devices.all.devices : d.hostname => d...
    if contains(keys(local.device_tags), d.hostname)
  }

  devices = { for hostname, ds in local.devices_by_hostname : hostname => ds[0] }
}

data "tailscale_devices" "all" {}

resource "tailscale_device_tags" "device" {
  for_each  = local.devices
  device_id = each.value.id
  tags      = local.device_tags[each.key]
}

moved {
  from = tailscale_device_tags.iapetus
  to   = tailscale_device_tags.device["iapetus"]
}

moved {
  from = tailscale_device_tags.sagittarius
  to   = tailscale_device_tags.device["sagittarius"]
}

moved {
  from = tailscale_device_tags.enceladus
  to   = tailscale_device_tags.device["enceladus"]
}

moved {
  from = tailscale_device_tags.enceladus_linux_vm
  to   = tailscale_device_tags.device["enceladus-linux-vm"]
}
