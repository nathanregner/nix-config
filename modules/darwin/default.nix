{
  self,
  inputs,
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
