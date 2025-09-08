{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs.unstable; [
    clang
    gnumake
  ];

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
      parsers = pkgs.unstable.vimPlugins.nvim-treesitter-parsers;
    in
    {
      hcl = {
        extensions = [
          "hcl"
          "tf"
        ];
        library = parsers.hcl;
      };
      dtd = {
        extensions = [
          "xml"
        ];
        library = parsers.dtd;
      };
    };
}
