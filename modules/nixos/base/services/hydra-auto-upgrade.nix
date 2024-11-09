{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.system.hydra-auto-upgrade;
in
{
  # derived from: https://github.com/Misterio77/nix-config/blob/main/modules/nixos/hydra-auto-upgrade.nix
  options = {
    system.hydra-auto-upgrade = {
      enable = lib.mkEnableOption "periodic hydra-based auto upgrade";

      dates = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "04:40";
        example = "daily";
      };

      operation = lib.mkOption {
        type = lib.types.enum [
          "switch"
          "boot"
        ];
        default = "boot";
      };
    };
  };

  config = lib.mkIf cfg.enable ({
    assertions = [
      {
        assertion = cfg.enable -> !config.system.autoUpgrade.enable;
        message = ''
          hydra-auto-upgrade and autoUpgrade are mutually exclusive.
        '';
      }
    ];

    environment.systemPackages = [ pkgs.hydra-auto-upgrade ];

    systemd.services.nixos-upgrade = lib.mkIf (cfg.dates != null) {
      description = "NixOS Upgrade";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig.Type = "oneshot";
      path = [
        pkgs.hydra-auto-upgrade
        config.nix.package
      ];
      script = ''
        hydra-auto-upgrade system ${cfg.operation}
      '';

      startAt = cfg.dates;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  });
}
