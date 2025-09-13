{ pkgs, ... }:
{
  home.packages = with pkgs.unstable; [
    ruff
    basedpyright
  ];
}
