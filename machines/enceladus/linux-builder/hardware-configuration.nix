{ modulesPath, lib, ... }:
{
  imports = [ "${modulesPath}/virtualisation/qemu-guest-agent.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";
  virtualisation = {
    cores = 8; # TODO: Figure out why this can't be > 8
    diskSize = lib.mkForce (64 * 1024);
  };
}
