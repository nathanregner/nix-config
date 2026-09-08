{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "viins";
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit -C";
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
    initExtraFirst = ''
      ZVM_SYSTEM_CLIPBOARD_ENABLED=true
      ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
    '';
    initContent = lib.mkMerge [
      # zprof must be loaded before everything else, since it
      # benchmarks the shell initialization.
      (lib.mkOrder 400 /* zsh */ ''
        if [ -n "$ZPROF" ]; then zmodload zsh/zprof; fi
      '')
      (lib.mkOrder 1450 /* zsh */ ''
        if [ -n "$ZPROF" ]; then zprof; fi
      '')

      /* zsh */ ''
        # === Replaces oh-my-zsh lib/completion.zsh ===
        zmodload -i zsh/complist
        WORDCHARS=""
        unsetopt menu_complete
        unsetopt flowcontrol
        setopt auto_menu
        setopt complete_in_word
        setopt always_to_end
        bindkey -M menuselect '^o' accept-and-infer-next-history
        zstyle ':completion:*:*:*:*:*' menu select
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
        zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
        zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
        zstyle ':completion::complete:*' use-cache 1
        zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh"

        # === Replaces oh-my-zsh lib/directories.zsh ===
        setopt auto_cd
        setopt auto_pushd
        setopt pushd_ignore_dups
        setopt pushdminus
        alias -g ...='../..'
        alias -g ....='../../..'
        alias -g .....='../../../..'
        alias -- -='cd -'
        for i in {1..9}; do alias "$i"="cd -$i"; done
        alias md='mkdir -p'
        alias rd=rmdir

        flakify() {
          nix flake new -t github:NixOS/templates#''${1:-"utils-generic"} .
        }

        nixify() {
          cp ${./templates}/{shell.nix,.envrc} .
          chmod +w {shell.nix,.envrc}
        }

        catwhich() {
          cat "$(which "$1")"
        }
        compdef catwhich=which

        # https://github.com/NixOS/nixpkgs/issues/275770
        complete -C aws_completer aws

        ${lib.optionalString pkgs.stdenv.isDarwin ''
          source ${./zsh/completions/_launchctl}
        ''}
      ''
    ];
    oh-my-zsh.enable = false;
    shellAliases =
      let
        sys = if pkgs.stdenv.isDarwin then "darwin" else "os";
      in
      {
        nrb = "nh ${sys} build .";
        nrr = "nh ${sys} repl .";
        snrb = "nh ${sys} boot .";
        snrs = "nh ${sys} switch .";
        snrt = "nh ${sys} test .";

        hmb = "nh home build .";
        hmr = "nh home repl .";
        hms = "nh home switch .";

        cdiff = "diff --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format=' %L'"; # diff with full context

        g- = /* bash */ ''
          root="$(git rev-parse --show-toplevel)";
          if [ "$PWD" = "$root" ]; then
            parent="$(git -C .. rev-parse --show-toplevel 2>/dev/null)" && cd "$parent";
          else
            cd "$root";
          fi
        '';
        lg = "lazygit";

        # https://www.reddit.com/r/NixOS/comments/8m1n3d/comment/dzkfwhl/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        nix-stray-roots = ''nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/\w+-system|\{memory)"'';
      };
  };
}
