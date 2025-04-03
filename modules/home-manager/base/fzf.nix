{
  programs.fzf = rec {
    enable = true;
    enableZshIntegration = true;
    # https://github.com/sharkdp/fd#using-fd-with-fzf
    defaultCommand = "fd --hidden --follow --exclude .git";
    fileWidgetCommand = defaultCommand;
    defaultOptions = [
      "--ansi"
      # https://github.com/catppuccin/fzf
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
  };

  # https://github.com/junegunn/fzf
  programs.zsh.initExtraFirst = ''
    # Use fd (https://github.com/sharkdp/fd) instead of the default find
    # command for listing path candidates.
    # - The first argument to the function ($1) is the base path to start traversal
    # - See the source code (completion.{bash,zsh}) for the details.
    _fzf_compgen_path() {
      fd --hidden --follow --exclude ".git" . "$1"
    }

    # Use fd to generate the list for directory completion
    _fzf_compgen_dir() {
      fd --type d --hidden --follow --exclude ".git" . "$1"
    }
  '';
}
