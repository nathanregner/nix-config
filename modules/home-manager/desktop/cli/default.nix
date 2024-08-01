{ pkgs, ... }:
{
  imports = [
    ./git.nix
    ./zoxide.nix
    ./k9s.nix
    ./lazygit.nix
    ./nix.nix
    ./tmux-sessionizer.nix
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
