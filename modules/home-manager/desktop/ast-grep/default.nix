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
  json = pkgs.formats.json { };
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
        hcl = {
          extensions = [
            "hcl"
            "tf"
          ];
          library = pkgs.unstable.tree-sitter-grammars.tree-sitter-hcl;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs.unstable; [
      ast-grep
      tree-sitter
    ];

    home.file."sgconfig.yml" = {
      source = yaml.generate "sgconfig.yml" {
        customLanguages = builtins.mapAttrs (
          _: lang:
          {
            inherit (lang) extensions;
            libraryPath = "${lang.library}/parser";
          }
          // (lib.optionalAttrs (lang.expandoChar != null) {
            inherit (lang) expandoChar;
          })
        ) cfg.customLanguages;
        inherit (cfg) ruleDirs;
      };
    };

    # https://github.com/tree-sitter/tree-sitter/blob/21390af2dd7db090da850ea76ef5ba27d37c41d6/docs/src/cli/init-config.md#parser-directories
    xdg.configFile."tree-sitter/config.json".source = json.generate "tree-sitter-cli-config.json" {
      "parser-directories" = [
        (pkgs.linkFarm "tree-sitter-parser-directory" (
          lib.mapAttrsToList (name: lang: {
            inherit name;
            path = lang.library;
          }) cfg.customLanguages
        ))
      ];
    };
  };
}
