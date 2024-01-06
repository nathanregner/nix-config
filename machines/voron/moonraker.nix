{ config, ... }: {
  services.moonraker = {
    enable = true;
    allowSystemControl = true;

    settings = {
      authorization = {
        cors_domains = [ "*://voron.nregner.net" "*://voron" ];
        trusted_clients = [ "127.0.0.0/8" "::1/128" ];
      };
      history = { };
      # required by KAMP
      file_manager.enable_object_processing = "True";
    };
  };

  services.backups.moonraker = {
    paths = [ config.services.moonraker.stateDir ];
    restic = { s3 = { }; };
  };

  # required for allowSystemControl
  security.polkit.enable = true;

  # use bleeding edge
  nixpkgs.overlays = [ (final: prev: { inherit (final.unstable) moonraker; }) ];
}
