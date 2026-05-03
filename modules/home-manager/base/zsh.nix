{
  config,
  pkgs,
  lib,
  ...
}:
let
  zcompdump = "${config.programs.zsh.dotDir}/.zcompdump";
in
{
  home.activation.clearZshCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -f "${zcompdump}"*
  '';

  programs.zsh = {
    enable = true;
    # zprof.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    completionInit = "autoload -Uz compinit && compinit -C";
    initContent = lib.mkMerge [
      # before fzf (910) to fix ctrl-r binding precedence
      (lib.mkOrder 900 /* bash */ ''
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/vi-mode/vi-mode.plugin.zsh
        bindkey -M viins 'jk' vi-cmd-mode
      '')
      /* bash */ ''
        # enable omz-style completion highlighting
        zmodload -i zsh/complist
        setopt auto_menu
        zstyle ':completion:*:*:*:*:*' menu select

        setopt AUTO_CD

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

        compinit-refresh() {
          rm -f "${zcompdump}"*
          autoload -Uz compinit && compinit
          echo "Completion cache regenerated"
        }
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          source ${./zsh/completions/_launchctl}
        ''}
      ''
    ];
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
