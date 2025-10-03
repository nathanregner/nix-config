{ modulesPath, config, ... }:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../modules/nixos/server
    ./hardware-configuration.nix
    ./services
  ];

  networking = {
    hostName = "voron";
    useNetworkd = true;
  };

  sops.secrets.ddns.key = "route53/ddns";
  services.route53-ddns = {
    enable = true;
    domain = "voron.nregner.net";
    ipType = "lan";
    ttl = 60;
    environmentFile = config.sops.secrets.ddns.path;
  };

  sops.defaultSopsFile = ./secrets.yaml;

  local.programs.home-manager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
