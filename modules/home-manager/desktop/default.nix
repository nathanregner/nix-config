{ inputs, outputs, pkgs, ... }: {
  imports = [
    #
    ../base
    ./alacritty.nix
    ./cli
    ./jetbrains
    ./nvim
    ./sops.nix
    ./theme.nix
  ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  home.packages = with pkgs.unstable; [
    # apps
    discord
    # firefox
    # gparted

    # tools
    pkgs.attic
    awscli2
    gh
    jq
    nushellFull
    pv
    xclip

    # nix
    comma # auto-run from nix-index: https://github.com/nix-community/comma
    nix-output-monitor
    nix-prefetch
    nixfmt
    nix-du # nix-du -s=500MB | xdot -
    xdot
  ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      open = "xdg-open";
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };
  };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
