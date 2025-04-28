{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
  json = pkgs.formats.json { };
  cfg = config.programs.topiary;
in
{
  options.programs.topiary = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    package = lib.mkPackageOption pkgs.unstable "topiary" { };

    finalPackage = mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      default = pkgs.runCommand "topiary" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        makeWrapper ${lib.getExe cfg.package} $out/bin/topiary \
          --set TOPIARY_CONFIG_FILE "${config.xdg.configHome}/topiary/languages.ncl" \
          --set TOPIARY_LANGUAGE_DIR "${config.xdg.configHome}/topiary/languages"
      '';
    };

    languages = mkOption {
      type = types.listOf (
        types.oneOf [
          types.package
          types.path
        ]
      );
      default = [
        "${cfg.package}/share/queries"
      ];
    };

    settings.languages = mkOption {
      description = "https://topiary.tweag.io/book/cli/configuration.html";
      type = types.attrsOf (
        types.submodule {
          options = {
            extensions = mkOption {
              type = types.listOf types.str;
            };
            indent = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            grammar = mkOption {
              type = types.submodule {
                options = {
                  source.path = mkOption {
                    type = types.oneOf [
                      types.package
                      types.path
                      types.str
                    ];
                  };
                  symbol = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                      If symbol of the language in the compiled grammar. Usually this is
                      `tree_sitter_<LANGUAGE_NAME>`, but in rare cases it differs. For instance our
                      "tree-sitter-query" language, where the symbol is: `tree_sitter_query` instead
                      of `tree_sitter_tree_sitter_query`.
                    '';
                  };
                };
              };
              default = 1;
            };
            workspaces = mkOption {
              type = types.listOf types.int;
              default = [ ];
            };
          };
        }
      );
      default = {
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."topiary/languages".source = pkgs.srcOnly {
      name = "topiary-languages";
      version = "latest";
      srcs = cfg.languages;
      stdenv = pkgs.stdenvNoCC;
    };

    xdg.configFile."topiary/languages.ncl".text = ''
      import "${json.generate "topiary-languages.json" cfg.settings}"
    '';

    programs.topiary.settings.languages = {
      toml = {
        extensions = [ "toml" ];
        grammar.source.path = "${pkgs.tree-sitter-grammars.tree-sitter-toml}/parser";
      };
      tree_sitter_query = {
        extensions = [ "scm" ];
        grammar = {
          source.path = "${pkgs.tree-sitter-grammars.tree-sitter-query}/parser";
          symbol = "tree_sitter_query";
        };
      };
    };

    home.packages = [
      cfg.finalPackage
    ];
  };
}
