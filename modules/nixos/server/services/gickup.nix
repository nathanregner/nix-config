# derived from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/networking/r53-ddns.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.gickup;
in
{
  options = {
    services.gickup = {
      enable = mkEnableOption "gickup";

      config = mkOption {
        type = types.attrsOf types.any;
      };

      interval = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          Systemd calendar expression when to check for ip changes.
          See {manpage}`systemd.time(7)`.
        '';
      };

      configFile = mkOption {
        type = types.oneOf types.path;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.timers.gickup = {
      description = "gickup timer";

      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.interval;
      };
    };

    systemd.services.gickup = {
      description = "gickup service";

      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];

      serviceConfig.EnvironmentFile = cfg.environmentFile;

      script = ''
        ${pkgs.gickup}/bin/gickup ${cfg.configFile}
      '';
    };
  };
}
