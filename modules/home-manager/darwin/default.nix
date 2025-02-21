{ pkgs, ... }:
{
  imports = [
    ./hammerspoon.nix
    ./scroll-reverser.nix
  ];

  # prefer these over system utilities for consistency with linux
  home.packages = with pkgs.unstable; [
    coreutils-full
    diffutils
    util-linux
  ];
}
