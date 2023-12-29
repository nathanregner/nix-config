{ pkgs, ... }: {
  imports = [
    #
    ./git.nix
    ./k9s.nix
    ./nix.nix
  ];

  home.packages = with pkgs.unstable; [
    # text manipulation
    gawk
    gnused
    jq
    ripgrep
    vim

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
  ];
}

