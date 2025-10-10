{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
  cfg = config.programs.topiary;
  package = pkgs.topiary;
  json = pkgs.formats.json { };

  parserPath = package: "${package}/parser";
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
        makeWrapper ${lib.getExe package} $out/bin/topiary \
          --set TOPIARY_LANGUAGE_DIR "${config.xdg.configHome}/topiary/languages" \
          --set TOPIARY_CONFIG_FILE "${config.xdg.configHome}/topiary/languages.ncl"
      '';
    };

    languages = mkOption {
      description = "https://topiary.tweag.io/book/cli/configuration.html";
      type = types.attrsOf (
        types.submodule {
          options = {
            extensions = mkOption {
              type = types.listOf types.str;
            };
            grammar = mkOption {
              type = types.submodule {
                options = {
                  package = mkOption {
                    type = types.package;
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
            indent = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            queries = mkOption {
              type = types.nullOr types.path;
              default = null;
            };
          };
        }
      );
    };
  };

  config = lib.mkIf (cfg.enable && cfg.languages or null != null) {
    xdg.configFile."topiary/languages".source = "${pkgs.runCommandLocal "topiary-queries" { } ''
      mkdir $out
      cp ${package}/share/queries/* $out/
      ${builtins.concatStringsSep "\n" (
        lib.mapAttrsToList (name: language: ''
          if [ ! -f "${parserPath language.grammar.package}" ]; then
            echo "Path ${parserPath language.grammar.package} does not exist."
            exit 1
          fi

          ${lib.optionalString (language.queries != null) ''
            if [ ! -f "${language.queries}" ]; then
              echo "Path ${language.queries} does not exist."
              exit 1
            fi
            cp "${language.queries}" $out/${name}.scm
          ''}
        '') cfg.languages
      )}
    ''}";

    xdg.configFile."topiary/languages.ncl".text =
      let
        languages = {
          languages = builtins.mapAttrs (
            _: language:
            language
            // {
              grammar = {
                inherit (language.grammar) symbol;
                source.path = parserPath language.grammar.package;
              };
            }
          ) cfg.languages;
        };
      in
      ''
        import "${json.generate "topiary-languages.json" languages}"
      '';

    home.packages = [
      cfg.finalPackage
    ];
  };
}
