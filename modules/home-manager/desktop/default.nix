{
  inputs,
  outputs,
  ...
}:
{
  imports = [
    ../base
    ./alacritty.nix
    ./cli
    ./firefox
    ./insync.nix
    ./jetbrains
    ./nvim
    ./theme.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix.registry.nixpkgs.to = {
    type = "path";
    path = inputs.nixpkgs-unstable;
  };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
