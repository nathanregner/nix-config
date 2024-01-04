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
}
