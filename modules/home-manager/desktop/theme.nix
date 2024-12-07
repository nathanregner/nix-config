{ inputs, pkgs, ... }:
{
  imports = [
    inputs.catppuccin-nix.homeManagerModules.catppuccin
    ./theme.linux.nix
  ];

  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };

  # fc-cache -rf to clear
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.unstable.nerd-fonts.jetbrains-mono
    pkgs.sf-mono-nerd-font
  ];
}
