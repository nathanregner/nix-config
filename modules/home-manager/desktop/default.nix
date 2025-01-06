{ inputs, outputs, ... }:
{
  imports = [
    ../base
    ./alacritty.nix
    ./cli
    ./firefox
    ./insync.nix
    ./jetbrains
    ./nvim
    ./sops.nix
    ./theme.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit outputs; };

  nix.registry = {
    # pin the flake registry to inputs to avoid extra downloads
    nixpkgs.flake = inputs.nixpkgs;
    nixpkgs-stable.flake = inputs.nixpkgs;

    # also pin a "github" entry for use of `nix flake lock --override-input nixpkgs "flake:nixpkgs-git"` in other flakes
    # unlike the above entries, this won't result in a store path in the lockfile
    nixpkgs-git.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs-unstable.rev;
      type = "github";
    };
    nixpkgs-stable-git.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      type = "github";
    };
  };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
