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
  programs.zsh.initExtraFirst = # bash
    ''
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

      # # https://github.com/junegunn/fzf/discussions/2800#discussioncomment-7931813
      # export FZF_CTRL_R_OPTS="$(
      #     cat << EOF
      #   --bind "ctrl-d:execute(sed -i "" '$d' $HISTFILE)+reload:fc -pa $HISTFILE; fc -rl 1 |
      #     awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
      #   --bind "start:reload:fc -pa $HISTFILE; fc -rl 1 |
      #     awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
      #   --header 'enter select · ^d remove latest'
      #   --height 100%
      #   --preview-window "hidden:down:border-top:wrap:<70(hidden)"
      #   --preview "bat --plain --language sh <<<{2..}"
      #   --prompt " History > "
      #   --with-nth 2..
      #   EOF
      # )"
    '';
}
