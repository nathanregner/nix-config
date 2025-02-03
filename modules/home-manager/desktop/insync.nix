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
    ] ++ (lib.optional cfg.extensions.nautilus.enable pkgs.insync-nautilus);

    systemd.user.services.insync = {
      Service = {
        ExecStart = "${cfg.package}/bin/insync hide || ${cfg.package}/bin/insync start";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
