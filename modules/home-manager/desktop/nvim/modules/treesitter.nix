{
  pkgs,
  config,
  ...
}:
let
  parserPrefix = "nvim/nvim-treesitter";
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
  programs.neovim.lua.globals = (
    let
      parser_install_dir = "${config.xdg.dataHome}/${parserPrefix}";
    in
    {
      nvim_treesitter = {
        dir = "${package}";
        inherit parser_install_dir;
      };
      rtp = [ parser_install_dir ];
    }
  );

  # programs.neovim.extraPackages = with pkgs.unstable; [
  #   clang
  #   gnumake
  # ];

  xdg.dataFile =
    {
      "${parserPrefix}/queries" = {
        source = config.lib.file.mkFlakeSymlink ../after/queries;
        force = true;
      };
    }
    // builtins.listToAttrs (
      builtins.map (
        grammar:
        let
          language = builtins.elemAt (builtins.match "vimplugin-treesitter-grammar-(.*)" grammar.name) 0;
        in
        {
          name = "${parserPrefix}/parser/${language}.so";
          value = {
            source = "${grammar}/parser/${language}.so";
            force = true;
          };
        }
      ) package.passthru.dependencies
    );
}
