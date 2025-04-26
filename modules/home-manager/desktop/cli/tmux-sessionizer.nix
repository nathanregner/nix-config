{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.tmux-sessionizer;
  tomlFormat = pkgs.formats.toml { };

  configDir = if pkgs.stdenv.isDarwin then "Library/Application Support" else config.xdg.configHome;
in
{
  options.programs.tmux-sessionizer = {
    enable = lib.mkEnableOption "Enable tmux-sessionizer";

    session_sort_order = lib.mkOption {
      type = lib.types.str;
      default = "LastAttached";
    };

    excluded_dirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    search_dirs = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = {
        "${config.home.homeDirectory}/dev" = {
          depth = 3;
        };
        "${config.home.homeDirectory}/nix-config" = {
          depth = 2;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.unstable.tmux-sessionizer ];
    home.file."${configDir}/tms/config.toml".source = tomlFormat.generate "tms-config" {
      inherit (cfg) excluded_dirs session_sort_order;
      search_dirs = lib.mapAttrsToList (path: cfg: cfg // { inherit path; }) cfg.search_dirs;
    };
  };
}
