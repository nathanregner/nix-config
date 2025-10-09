{ config, lib, ... }:
{
  programs.vim.enable = lib.mkDefault (!config.programs.neovim.enable);

  # expose file to ideavimrc
  home.file.".vimrc".text = ''
    inoremap jk <esc>

    set smartcase
    set number relativenumber

    " Allow saving of files as sudo
    cmap w!! w !sudo tee %
  '';
}
