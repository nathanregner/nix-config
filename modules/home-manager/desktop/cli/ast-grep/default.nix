{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.ast-grep;
  yaml = pkgs.formats.yaml { };
in
{
  options.programs.ast-grep = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    ruleDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    customLanguages = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            extensions = mkOption {
              type = types.listOf types.str;
              example = [ "md" ];
            };
            library = mkOption {
              type = types.package;
            };
            expandoChar = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "_";
            };
          };
        }
      );
      default = {
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs.unstable; [
      ast-grep
    ];

    home.file."sgconfig.yml" = {
      source = yaml.generate "sgconfig.yml" {
        customLanguages = builtins.mapAttrs (
          name: lang:
          {
            inherit (lang) extensions;
            libraryPath = "${lang.library}/parser/${name}.so";
          }
          // (lib.optionalAttrs (lang.expandoChar != null) {
            inherit (lang) expandoChar;
          })
        ) cfg.customLanguages;
        inherit (cfg) ruleDirs;
      };
    };
  };
}
