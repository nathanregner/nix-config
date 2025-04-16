{
  pkgs,
  config,
  ...
}:
let
  package = pkgs.unstable.vimPlugins.avante-nvim;
in
{
  programs.neovim.lua.globals = {
    avante = {
      dir = "${package}";
    };
  };
}
