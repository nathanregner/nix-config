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
          [[ ! "$(tty)" =~ dev/tty[0-9] ]] &&
          [[ ! "$TERMINAL_EMULATOR" =~ "JetBrains" ]]; then
          $_tmux attach >&/dev/null
        fi

        # clear scrollback buffer if tmux is running
        if [[ $TMUX ]]; then
          alias clear='clear && tmux clear-history'
        fi
      '';

    shellAliases = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      open = "xdg-open";
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };
  };
}
