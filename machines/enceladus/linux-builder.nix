{ lib, ... }: {
  imports = [ ../../modules/nixos/server ];

  virtualisation = {
    cores = 8; # TOOD: Figure out why this can't be > 8
    diskSize = lib.mkForce (64 * 1024);
  };

  networking.hostName = "m3-linux-builder";
  # FIXME: Have to manually run /run/current-system/activate to get secrets to show up...
  sops.defaultSopsFile = null;

  services.tailscaled-autoconnect = {
    enable = true;
    secret-key = "tailscale/builder_key";
  };

  users.users.nregner = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJN0UxPvRjkqYdq8OFtzO/borc4lU4QNYSJiGhgx3MkI"
    ];
  };

  # TODO: Remove
  nix.settings.substituters = lib.mkForce [ "https://cache.nixos.org" ];
}

