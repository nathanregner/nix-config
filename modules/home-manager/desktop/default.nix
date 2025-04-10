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
  nixpkgs = import ../../../nixpkgs.nix { inherit outputs; };

  nix.registry = {
    nixpkgs.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs-unstable.rev;
      type = "github";
    };
    nixpkgs-stable.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      type = "github";
    };
  };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
