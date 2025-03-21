{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      live-restore = false;
      # insecure-registries = [ "http://sagittarius:${toString config.services.dockerRegistry.port}" ];
    };
  };

  environment.systemPackages = with pkgs; [ docker-compose ];

  # services.dockerRegistry = {
  #   enable = true;
  #   listenAddress = "0.0.0.0";
  #   port = 5000;
  # };
}
