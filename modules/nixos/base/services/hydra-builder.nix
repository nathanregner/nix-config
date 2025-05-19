{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.hydra-sentinel.nixosModules.client ];

  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "Register this machine as a Hydra builder";
  };

  config = lib.mkIf config.local.services.hydra-builder.enable {
    services.hydra-sentinel-client = {
      enable = true;
      settings = {
        serverAddr = "sagittarius:3002";
      };
    };
  };
}
