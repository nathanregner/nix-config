{
  catppuccin.zsh-syntax-highlighting.enable = true;
  programs.zsh = {
    enable = true;
    initContent = builtins.readFile ./zshrc.zsh;
    syntaxHighlighting.enable = true;
  };
}
