{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;

    syntaxHighlighting = {
      enable = true;
      catppuccin.enable = true;
    };

    initExtra =
      # bash
      ''
        if typeset -f tmux >/dev/null; then
          unset -f tmux
        fi
        _tmux=$(which tmux)

        # Name new sessions after pwd
        tmux() {
          if [[ -z "$@" ]]; then
            pwd=$(pwd)
            session_name=$(basename "$pwd")
            $_tmux new-session -s "$session_name" || $_tmux attach -t "$session_name"
          else
            $_tmux "$@"
          fi
        }

        # Auto-start tmux
        if command -v tmux &>/dev/null &&
          [ -n "$PS1" ] &&
          [[ ! "$TERM" =~ screen ]] &&
          [[ ! "$TERM" =~ tmux ]] &&
          [ -z "$TMUX" ] &&
          [[ ! "$(tty)" =~ dev/tty ]] &&
          [[ ! "$TERMINAL_EMULATOR" =~ "JetBrains" ]]; then
          $_tmux attach >&/dev/null
        fi
      '';

    shellAliases = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      open = "xdg-open";
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };
  };
}
