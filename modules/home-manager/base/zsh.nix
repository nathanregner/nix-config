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
    initContent = ''
      bindkey -M viins 'jk' vi-cmd-mode

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
    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''
      source ${./zsh/completions/_launchctl}
    '';
    # defaultKeymap = "viins";
    oh-my-zsh = {
      enable = true;
      plugins = [ "vi-mode" ];
    };
    shellAliases =
      let
        sys = if pkgs.stdenv.isDarwin then "darwin" else "os";
      in
      rec {
        nrb = "nh ${sys} build .";
        nrr = "nh ${sys} repl .";
        snrb = "sudo nh ${sys} boot .";
        snrs = "sudo nh ${sys} switch .";
        snrt = "sudo nh ${sys} test .";

        hmb = "nh home build .";
        hmr = "nh home repl .";
        hms = "nh home switch .";

        cdiff = "diff --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format=' %L'"; # diff with full context

        lg = "lazygit";

        # https://www.reddit.com/r/NixOS/comments/8m1n3d/comment/dzkfwhl/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        nix-stray-roots = ''nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/\w+-system|\{memory)"'';
      };
  };
}
