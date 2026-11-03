{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hydra-sentinel.nixosModules.client
    # use bleeding edge (nixos-26.11)
    "${inputs.nixpkgs-unstable}/nixos/modules/services/continuous-integration/hydra/builder.nix"
  ];

  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "Register this machine as a Hydra builder";
  };

  config = lib.mkMerge [
    {
      services.hydra-builder = {
        package = lib.mkDefault pkgs.unstable.hydra-builder;
        queueRunnerAddr = lib.mkDefault "http://sagittarius:50051";
      };
    }
    (lib.mkIf config.local.services.hydra-builder.enable {
      services.hydra-builder.enable = true;

      services.hydra-sentinel-client = {
        enable = true;
        settings = {
          serverAddr = "sagittarius:3002";
        };
      };
    })
  ];
}
