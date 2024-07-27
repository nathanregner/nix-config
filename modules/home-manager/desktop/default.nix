{ outputs, ... }:
{
  imports = [
    ../base
    ./alacritty.nix
    ./cli
    ./firefox
    ./jetbrains
    ./nvfetcher.nix
    ./nvim
    ./sops.nix
    ./theme.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit outputs; };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
