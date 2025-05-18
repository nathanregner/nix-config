{ config, lib, ... }:
{
  imports = [
    ../base
    ./services
    ./programs
  ];

  services.prometheus-host-metrics.enable = lib.mkDefault true;

  services.tailscaled-autoconnect = {
    enable = lib.mkDefault true;
    secretPath = lib.mkDefault config.sops.secrets.tailscale-auth-key.path;
  };

  sops.secrets.tailscale-auth-key = {
    sopsFile = ./services/secrets.yaml;
    key = "tailscale/server_key";
  };

  system.hydra-auto-upgrade.enable = lib.mkDefault true;

}
