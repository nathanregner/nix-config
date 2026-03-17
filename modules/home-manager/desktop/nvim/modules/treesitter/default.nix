{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.neovim.treesitter;
  parserPrefix = "nvim/site";
in
{
  options.programs.neovim.treesitter = {
    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.unstable.vimPlugins.nvim-treesitter;
    };

    finalPackage = mkOption {
      default =
        if cfg.package != null then
          if cfg.grammars == [ ] then
            cfg.package.withAllGrammars
          else
            cfg.package.withPlugins (plugins: (map (name: plugins.${name}) cfg.grammars))
        else
          null;
      readOnly = true;
    };

    grammars = mkOption {
      type = types.listOf types.str;
      default = builtins.filter (line: line != "") (
        lib.splitString "\n" (builtins.readFile ./grammars.txt)
      );
    };
  };

  config = {
    programs.neovim.lua.globals = lib.optionalAttrs (cfg.finalPackage != null) (
      let
        install_dir = "${config.xdg.dataHome}/${parserPrefix}";
      in
      {
        nvim-treesitter = {
          dir = "${cfg.finalPackage}";
          opts = { inherit install_dir; };
        };
        rtp = [
          "${cfg.finalPackage}/runtime"
        ];
      }
    );

    # :checkhealth nvim-treesitter
    home.packages = lib.optionals (cfg.finalPackage == null || cfg.grammars != [ ]) (
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

    xdg.dataFile = lib.optionalAttrs (cfg.finalPackage != null) (
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
          ) cfg.finalPackage.passthru.dependencies
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
