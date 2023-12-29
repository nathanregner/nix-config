{ inputs, lib, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/jetbrains
    ../../terraform/tailscale
    inputs.mac-app-util.homeManagerModules.default
  ];

  programs.alacritty.settings = { font = { size = lib.mkForce 11; }; };

  home = {
    username = "nregner";
    homeDirectory = "/Users/nregner";
    flakePath = "/Users/nregner/nix-config";
    # Use a case-sensitive file system for nix builds
    sessionVariables = { TMPDIR = "/Volumes/tmp"; };
  };

  home.packages = with pkgs.unstable; [
    # tools
    awscli2
    fd
    gh
    jq
    nushell
    pv
    ripgrep
    rsync

    libiconv
    rustup

    nix
    comma # auto-run from nix-index: https://github.com/nix-community/comma
    nix-output-monitor
    nix-prefetch
    nixfmt
    # nix-du # nix-du -s=500MB | xdot -
    pkgs.xdot-darwin

    rectangle
  ];

  programs.zsh = {
    shellAliases = {
      snr = lib.mkForce "sudo darwin-rebuild --flake .";
      snrs = lib.mkForce "sudo darwin-rebuild --flake . switch";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
