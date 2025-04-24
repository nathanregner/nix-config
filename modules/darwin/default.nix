{
  self,
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.mac-app-util.darwinModules.default
    ../nixos/base/nix.nix
    ../nixos/desktop/nix.nix
    ./hydra-builder.nix
    ./nix.nix
    ./preferences.nix
    ./sops.nix
  ];

  nix = {
    settings = {
      # https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = lib.mkForce false;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # required by Spoons/ControlEscape
  };

  programs.ssh.knownHosts = self.globals.ssh.knownHosts;
}
