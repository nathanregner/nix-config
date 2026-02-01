{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.neovim.treesitter;
  package = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars;
  parserPrefix = "nvim/nvim-treesitter";
in
{
  options.programs.neovim.treesitter = {
    grammarSource = lib.mkOption {
      type = lib.types.enum [
        "nix"
        "git"
      ];
      default = "nix";
    };
  };

  config = {
    programs.neovim.lua.globals = lib.optionalAttrs (cfg.grammarSource == "nix") (
      let
        parser_install_dir = "${config.xdg.dataHome}/${parserPrefix}";
      in
      {
        nvim-treesitter = {
          dir = "${package}";
          inherit parser_install_dir;
        };
        rtp = [ parser_install_dir ];
      }
    );

    # :checkhealth nvim-treesitter
    home.packages = lib.optionals (cfg.grammar == "git") (
      with pkgs.unstable;
      [
        curl
        gnumake
        gnutar
        stdenv.cc
        tree-sitter-latest
      ]
    );

    xdg.configFile."nvim/after/queries" = {
      source = config.lib.file.mkFlakeSymlink ./queries;
      force = true;
    };

    xdg.dataFile = lib.optionalAttrs (cfg.grammarSource == "nix") (
      lib.listToAttrs (
        map (name: grammar: {
          name = "${parserPrefix}/parser/${name}.so";
          value = {
            source = "${grammar}/parser";
            force = true;
          };
        }) package.passthru.dependencies
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
