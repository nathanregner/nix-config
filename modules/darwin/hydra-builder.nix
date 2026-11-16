{
  self,
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.hydra-sentinel.darwinModules.client
    inputs.hydra.darwinModules.builder
  ];

  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "Register this machine as a Hydra builder";
  };

  config = lib.mkMerge [
    {
      services.hydra-queue-builder-dev.queueRunnerAddr = lib.mkDefault "http://sagittarius:${toString self.globals.services.hydra.grpcPort}";
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
