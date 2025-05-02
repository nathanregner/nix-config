{ inputs, pkgs, ... }:
{
  imports = [
    inputs.catppuccin-nix.homeModules.catppuccin
    ./theme.linux.nix
  ];

  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };

  # fc-cache -rf to clear
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.local.sf-mono-nerd-font
    pkgs.unstable.nerd-fonts.jetbrains-mono
  ];
}
