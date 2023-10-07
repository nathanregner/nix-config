{ inputs, outputs, ... }: {
  imports = [
    #
    ../base
    ./alacritty.nix
    ./cli
    ./jetbrains
    ./nvim
    ./sops.nix
    ./theme.nix
    ./wezterm.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
