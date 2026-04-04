{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.neovim.treesitter;
  parserPrefix = "nvim/site";
in
{
  options.programs.neovim.treesitter = {
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars;
    };
  };

  config = {
    programs.neovim.lua.globals = lib.optionalAttrs (cfg.package != null) (
      let
        install_dir = "${config.xdg.dataHome}/${parserPrefix}";
      in
      {
        nvim-treesitter = {
          dir = "${cfg.package}";
          opts = {
            inherit install_dir;
          };
        };
        rtp = [
          "${cfg.package}/runtime"
        ];
      }
    );

    # :checkhealth nvim-treesitter
    home.packages = lib.optionals (cfg.package == null) (
      with pkgs.unstable;
      [
        curl
        gnumake
        gnutar
        stdenv.cc
        tree-sitter
      ]
    );

    xdg.configFile."nvim/after/queries" = {
      source = config.lib.file.mkFlakeSymlink ./queries;
      force = true;
    };

    xdg.dataFile = lib.optionalAttrs (cfg.package != null) (
      lib.listToAttrs (
        builtins.filter (grammar: grammar ? name) (
          map (
            dependency:
            let
              match = builtins.match "nvim-treesitter-grammar-(.*)" (dependency.pname or "");
            in
            lib.optionalAttrs (match != null) (
              let
                language = builtins.elemAt match 0;
              in
              {
                name = "${parserPrefix}/parser/${language}.so";
                value = {
                  source = "${dependency}/parser/${language}.so";
                  force = true;
                };
              }
            )
          ) cfg.package.passthru.dependencies
        )
      )
    );

    programs.topiary.languages.tree_sitter_query = {
      extensions = [ "scm" ];
      grammar = {
        package = pkgs.tree-sitter-grammars.tree-sitter-query;
        symbol = "tree_sitter_query";
      };
    };

    programs.ast-grep.customLanguages =
      let
        parsers = pkgs.vimPlugins.nvim-treesitter.passthru.builtGrammars;
      in
      {
        terraform = {
          extensions = [
            "hcl"
            "tf"
          ];
          library = parsers.terraform;
        };
        xml = {
          extensions = [
            "xml"
          ];
          library = parsers.xml;
        };
      };
  };
}
