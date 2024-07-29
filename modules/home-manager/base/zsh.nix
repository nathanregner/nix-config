{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    initExtra = ''
      bindkey -M viins 'jk' vi-cmd-mode

      flakify() {
        nix flake new -t github:NixOS/templates#''${1:-"utils-generic"} .
      }

      # https://github.com/NixOS/nixpkgs/issues/275770
      complete -C aws_completer aws
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
      {
        jqless = "jq -C | less -r";

        nr = "${nixRebuild} --flake .";
        nrs = "${nixRebuild} --flake . switch";
        snr = "sudo ${nixRebuild} --flake .";
        snrs = "sudo ${nixRebuild} --flake . switch";

        hm = "home-manager --flake .";
        hms = "home-manager --flake . switch";

        npd = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
      };
  };
}
