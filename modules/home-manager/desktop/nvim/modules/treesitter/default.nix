{
  config,
  pkgs,
  lib,
  ...
}:
let
  parserPrefix = "nvim/nvim-treesitter";
in
{
  programs.neovim.lua.globals =
    let
      parser_install_dir = "${config.xdg.dataHome}/${parserPrefix}";
    in
    {
      nvim_treesitter = {
        dir = "${pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars}";
        inherit parser_install_dir;
      };
      rtp = [ parser_install_dir ];
    };

  xdg.configFile."nvim/after/queries" = {
    source = config.lib.file.mkFlakeSymlink ./queries;
    force = true;
  };

  xdg.dataFile = lib.mapAttrs' (name: grammar: {
    name = "${parserPrefix}/parser/${name}.so";
    value = {
      source = "${grammar}/parser";
      force = true;
    };
  }) pkgs.unstable.vimPlugins.nvim-treesitter.passthru.builtGrammars;

  programs.topiary.languages.tree_sitter_query = {
    extensions = [ "scm" ];
    grammar = {
      package = pkgs.tree-sitter-grammars.tree-sitter-query;
      symbol = "tree_sitter_query";
    };
  };

  programs.ast-grep.customLanguages =
    let
      parsers = pkgs.unstable.vimPlugins.nvim-treesitter.passthru.builtGrammars;
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
}
