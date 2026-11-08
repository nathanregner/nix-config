{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.hydra-sentinel.nixosModules.client
    inputs.hydra.nixosModules.builder
  ];

  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "Register this machine as a Hydra builder";
  };

  config = lib.mkMerge [
    {
      services.hydra-queue-builder-dev.queueRunnerAddr = lib.mkDefault "http://sagittarius:50051";
    }
    (lib.mkIf config.local.services.hydra-builder.enable {
      services.hydra-queue-builder-dev.enable = true;

      services.hydra-sentinel-client = {
        enable = true;
        settings = {
          serverAddr = "sagittarius:3002";
        };
      };
    })
  ];
}
