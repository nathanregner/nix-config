{ pkgs, ... }:
{
  imports = [
    ./git
    ./k9s.nix
    ./lazygit.nix
    ./nix.nix
    ./starship.nix
    ./tmux-sessionizer.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  programs.tmux-sessionizer.enable = true;

  home.packages = with pkgs.unstable; [
    # text manipulation
    gawk
    gnused
    jq
    ripgrep
    parallel

    # filesystem
    fd
    file
    pv
    rsync
    tree
    which
    trash-cli

    # archive formats
    gnutar
    unzip
    xz
    zip
    zstd

    # system monitoring
    htop-vim

    # misc
    sops
  ];
}
