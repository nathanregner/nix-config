data "tailscale_device" "iapetus" {
  hostname = "iapetus"
}

resource "tailscale_device_tags" "iapetus" {
  device_id = data.tailscale_device.iapetus.id
  tags      = ["tag:admin", "tag:builder"]
}

data "tailscale_device" "sagittarius" {
  hostname = "sagittarius"
}

resource "tailscale_device_tags" "sagittarius" {
  device_id = data.tailscale_device.sagittarius.id
  tags      = ["tag:hydra", "tag:server"]
}

data "tailscale_device" "enceladus_linux_vm" {
  hostname = "enceladus-linux-vm"
}

resource "tailscale_device_tags" "enceladus_linux_vm" {
  device_id = data.tailscale_device.enceladus_linux_vm.id
  tags      = ["tag:builder"]
}

data "tailscale_device" "enceladus" {
  hostname = "enceladus"
}

resource "tailscale_device_tags" "enceladus" {
  device_id = data.tailscale_device.enceladus.id
  tags      = ["tag:admin", "tag:builder"]
}
