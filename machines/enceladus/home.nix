{ inputs, lib, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/jetbrains
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

  programs.zsh.shellAliases = {
    "vm-load" =
      "sudo launchctl load -w /Library/LaunchDaemons/org.nixos.linux-builder.plist";
    "vm-unload" =
      "sudo launchctl load -w /Library/LaunchDaemons/org.nixos.linux-builder.plist";
    "vm-logs" = "tail -f /var/log/darwin-builder.log";
  };

  home.packages = with pkgs.unstable; [
    # apps
    rectangle

    # tools
    awscli2
    gh
    nushell
    sops

    # nix
    comma # auto-run from nix-index: https://github.com/nix-community/comma
    nix-output-monitor
    nix-prefetch
    nixfmt
    # nix-du # nix-du -s=500MB | xdot -
    pkgs.xdot-darwin
    nixos-rebuild
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
