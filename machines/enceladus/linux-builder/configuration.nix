{
  self,
  lib,
  ...
}:
{
  imports = [
    ../../../modules/nixos/base/nix.nix
    ../../../modules/nixos/server/services/tailscaled-autoconnect.nix
    ./hardware-configuration.nix
    ./store-image.nix
    ./tailscale.nix
  ];

  networking.hostName = "enceladus-linux-vm";

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "http://sagittarius:${toString self.globals.services.hydra.grpcPort}";
    settings = {
      maxJobs = 8;
      supportedFeatures = [
        "benchmark"
        "big-parallel"
        "gccarch-armv8-a"
        "kvm"
        "nixos-test"
      ];
    };
  };

  users.users.timesync = {
    isSystemUser = true;
    group = "timesync";
    shell = "/run/current-system/sw/bin/bash";
    openssh.authorizedKeys.keys = [ self.globals.ssh.hostKeys.enceladus ];
  };

  users.groups.timesync = { };

  users.users.nregner = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
  };

  security.sudo.wheelNeedsPassword = false;

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
