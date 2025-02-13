{
  pkgs,
  config,
  ...
}:
let
  parserPrefix = "nvim/nvim-treesitter";
  package = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars;
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

  xdg.dataFile = builtins.listToAttrs (
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
