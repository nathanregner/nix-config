{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    initContent =
      ''
        bindkey -M viins 'jk' vi-cmd-mode

        flakify() {
          nix flake new -t github:NixOS/templates#''${1:-"utils-generic"} .
        }

        nixify() {
          cp ${./templates}/{shell.nix,.envrc} .
          chmod +w {shell.nix,.envrc}
        }

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
        nixRebuild = if pkgs.stdenv.isDarwin then "darwin-rebuild" else "nixos-rebuild";
      in
      rec {
        jqless = "jq -C | less -r";
        cdiff = "diff --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format=' %L'"; # diff with full context

        nr = "${nixRebuild} --flake .";
        nrb = "${nr} build";
        snr = if pkgs.stdenv.isDarwin then "sudo ${nr}" else "${nr} --sudo";
        snrb = "${snr} boot";
        snrs = "${snr} switch";
        snrt = "${snr} test";

        hm = "home-manager --flake .";
        hmb = "${hm} build";
        hms = "${hm} switch";

        "g-" = ''cd "$(git rev-parse --show-toplevel)"'';
        "lg" = "lazygit";

        # https://www.reddit.com/r/NixOS/comments/8m1n3d/comment/dzkfwhl/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        "nix-stray-roots" =
          ''nix-store --gc --print-roots | egrep -v "^(/nix/var|/run/\w+-system|\{memory)"'';
      };
  };
}
