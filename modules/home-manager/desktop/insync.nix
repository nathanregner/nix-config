{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) literalExpression types;
  inherit (lib.options) mkEnableOption mkOption;
  cfg = config.programs.insync;
in
{
  options.programs.insync = {
    enable = mkEnableOption "insync";

    package = mkOption {
      type = types.package;
      default = pkgs.insync;
      defaultText = literalExpression "pkgs.insync";
    };

    extensions.nautilus.enable = mkEnableOption "insync nautilus extension";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ (lib.optional cfg.extensions.nautilus.enable pkgs.insync-nautilus);

    # adapted from https://aur.archlinux.org/packages/insync
    systemd.user.services.insync = {
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Environment = [ "DISPLAY=:0" ];
        ExecStart = pkgs.writeShellScript "start-insync" "${cfg.package}/bin/insync hide || ${cfg.package}/bin/insync start";
        ExecStop = "${cfg.package}/bin/insync quit";
        RemainAfterExit = "yes";
        Type = "oneshot";
      };
      Unit = {
        After = [
          "local-fs.target"
          "network.target"
        ];
      };
    };
  };
}
