{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
  };
  catppuccin.bat.enable = true;
  home.packages = [ pkgs.unstable.bat-extras.batgrep ];
}
