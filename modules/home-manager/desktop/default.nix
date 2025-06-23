{ inputs, outputs, ... }:
{
  imports = [
    ../base
    ./alacritty.nix
    ./ast-grep
    ./cli
    ./firefox
    ./insync.nix
    ./jetbrains
    ./nvim
    ./sops.nix
    ./terraform
    ./theme.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
