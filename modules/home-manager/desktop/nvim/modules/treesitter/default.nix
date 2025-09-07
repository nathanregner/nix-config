{
  pkgs,
  config,
  ...
}:
let
  package = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars.overrideAttrs (old: {
    patches = old.patches or [ ] ++ [
      (pkgs.fetchpatch {
        url = "https://github.com/nvim-treesitter/nvim-treesitter/pull/7742/commits/fbcafd3e51200b3788652aef90147caade380750.patch";
        sha256 = "sha256-wOScAN6QqTW18HskDyNLbeg8Zgf5WNLYu39Hef0TQj8=";
      })
    ];
  });
in
{
  programs.neovim.lua.globals = {
    nvim-treesitter.dir = "${package}";
  };

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
