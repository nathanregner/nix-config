{ self, lib, ... }:
{
  imports = [
    ../../../modules/nixos/base/nix.nix
    ../../../modules/nixos/server/services/tailscaled-autoconnect.nix
    ./hardware-configuration.nix
    ./store-image.nix
    ./tailscale.nix
  ];

  networking.hostName = "enceladus-linux-vm";

  users.users.timesync = {
    isSystemUser = true;
    group = "timesync";
    shell = "/run/current-system/sw/bin/bash";
    openssh.authorizedKeys.keys = [ self.globals.ssh.hostKeys.enceladus ];
  };

  users.groups.timesync = { };

  security.sudo.extraRules = [
    {
      users = [ "timesync" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/date";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # don't rebuild vm image on every commit
  system.nixos.tags = lib.mkForce [ ];
}
