{ config, lib, ... }:
{
  imports = [
    ../../modules/nixos/server
    ./hardware-configuration.nix
    ./services
  ];

  networking.hostName = "sagittarius";

  programs.nregner.home-manager.enable = true;

  nix.buildMachines = lib.mkForce [
    {
      protocol = "ssh-ng";
      hostName = "iapetus";
      sshUser = "nregner";
      systems = [ "x86_64-linux" ];
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 12;
      speedFactor = 2;
    }
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets.ddns.key = "route53/ddns";
  services.route53-ddns = {
    enable = true;
    domain = "nregner.net";
    ipType = "public";
    ttl = 900;
    environmentFile = config.sops.secrets.ddns.path;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
