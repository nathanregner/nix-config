{ pkgs, lib, ... }:
{
  imports = [
    ./hammerspoon.nix
    ./scroll-reverser.nix
    ./claude-code.nix
  ];

  # https://github.com/nix-darwin/nix-darwin/issues/1307
  nix.gc.automatic = lib.mkForce false;

  # prefer these over system utilities for consistency with linux
  home.packages = with pkgs.unstable; [
    coreutils-full
    diffutils
    findutils
    util-linux
  ];
}
