{
  pkgs,
  config,
  ...
}:
{
  xdg.configFile."nvim/after/queries" = {
    source = config.lib.file.mkFlakeSymlink ./queries;
    force = true;
  };

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
}
