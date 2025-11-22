{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.python;
in
{
  options.programs.neovim.modules.python = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs.unstable; [
      ruff
      basedpyright
    ];
  };
}
