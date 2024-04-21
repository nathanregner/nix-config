{ inputs, pkgs, lib, ... }: {
  imports = [ inputs.catppuccin-nix.homeManagerModules.catppuccin ];

  catppuccin = {
    flavour = "mocha";
    accent = "blue";
  };

  fonts.fontconfig.enable = true;
  home.packages = [
    # nerdfonts is large - just use a subset
    (pkgs.unstable.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    pkgs.sf-mono-nerd-font
  ];

  gtk = {
    enable = pkgs.hostPlatform.isLinux;
    catppuccin = {
      enable = true;
      size = "compact";
      tweaks = [ "rimless" ];
    };
    iconTheme = {
      package = pkgs.unstable.catppuccin-papirus-folders;
      name = "Papirus-Dark";
    };
  };

  home.pointerCursor = lib.mkIf pkgs.hostPlatform.isLinux {
    name = "Catppuccin-Mocha-Dark-Cursors";
    package = pkgs.unstable.catppuccin-cursors.mochaDark;
    size = 24;
    gtk.enable = true;
  };
}
