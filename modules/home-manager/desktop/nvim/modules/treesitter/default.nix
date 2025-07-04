{
  pkgs,
  config,
  ...
}:
let
  parserPrefix = "nvim/nvim-treesitter";

  grammarOverrides = {
    # # FIXME: https://github.com/nix-community/tree-sitter-nix/pull/131
    # nix = old: {
    #   src = pkgs.fetchFromGitHub {
    #     owner = "nix-community";
    #     repo = "tree-sitter-nix";
    #     rev = "6c986c0076cebde9169fe8aedecbac0ecf5b9f24";
    #     hash = "sha256-HOfRadzgjRR3HZR/i0+tx130INTMvcDmc4n/4XExSDY=";
    #   };
    # };
  };

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
  programs.neovim.lua.globals =
    let
      parser_install_dir = "${config.xdg.dataHome}/${parserPrefix}";
    in
    {
      nvim_treesitter = {
        dir = "${package}";
        inherit parser_install_dir;
      };
      rtp = [ parser_install_dir ];
    };

  xdg.configFile."nvim/after/queries" = {
    source = config.lib.file.mkFlakeSymlink ./queries;
    force = true;
  };

  xdg.dataFile = builtins.listToAttrs (
    builtins.map (
      grammar:
      let
        language = builtins.elemAt (builtins.match "vimplugin-treesitter-grammar-(.*)" grammar.name) 0;
        override = grammarOverrides.${language} or null;
        finalGrammar = if override != null then grammar.overrideAttrs override else grammar;
      in
      {
        name = "${parserPrefix}/parser/${language}.so";
        value = {
          source = "${finalGrammar}/parser/${language}.so";
          force = true;
        };
      }
    ) package.passthru.dependencies
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
