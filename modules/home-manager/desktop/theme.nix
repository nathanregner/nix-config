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

  fonts.fontconfig.enable = true;
  home.packages = [
    # nerdfonts package is large; use a subset
    pkgs.unstable.nerd-fonts.jetbrains-mono
    pkgs.sf-mono-nerd-font
  ];
}
