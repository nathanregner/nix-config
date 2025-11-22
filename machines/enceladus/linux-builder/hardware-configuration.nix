{ lib, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";
  virtualisation = {
    cores = 8; # TODO: Figure out why this can't be > 8
    diskSize = lib.mkForce (64 * 1024);

    # https://www.reddit.com/r/qemu_kvm/comments/lboxit/time_sync_macos_host_linux_guest
    qemu.options = [
      "-rtc"
      "base=localtime,clock=host"
    ];
  };
}
