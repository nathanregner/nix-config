{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.services.hydra-builder;
  toml = pkgs.formats.toml { };
in
{
  imports = [ inputs.hydra-sentinel.darwinModules.client ];

  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "Register this machine as a Hydra builder";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.hydra-builder;
    };

    queueRunnerAddr = lib.mkOption {
      type = lib.types.str;
      default = "http://sagittarius:50051";
    };

    # see services.hydra-builder.settings in nixpkgs
    settings = lib.mkOption {
      inherit (toml) type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.hydra-sentinel-client = {
      enable = true;
      settings = {
        serverAddr = "sagittarius:3002";
      };
    };

    # nix-darwin port of services.hydra-builder; runs as root, which is a trusted nix user
    launchd.daemons.hydra-builder.serviceConfig = {
      ProgramArguments = [
        (lib.getExe cfg.package)
        "--gateway-endpoint"
        cfg.queueRunnerAddr
        "--config-path"
        "${toml.generate "builder.toml" cfg.settings}"
      ];
      EnvironmentVariables = {
        NIX_REMOTE = "daemon";
        RUST_BACKTRACE = "1";
        HOME = "/var/root";
        PATH = lib.makeBinPath [ config.nix.package ];
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/hydra-builder.log";
      StandardErrorPath = "/var/log/hydra-builder.log";
    };
  };
}
