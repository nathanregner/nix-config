{ pkgs, ... }:
{
  imports = [
    ./ast-grep
    ./bat.nix
    ./direnv
    ./eza.nix
    ./git
    ./k9s.nix
    ./lazygit
    ./nix.nix
    ./nushell
    ./starship.nix
    ./terraform
    ./tmux-sessionizer.nix
    ./topiary.nix
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

    # filesystem
    dua
    fd
    file
    pv
    rsync
    tree
    which
    trash-cli

    # archive formats
    ouch

    # system monitoring
    htop-vim

    # misc
    sops
  ];
}
