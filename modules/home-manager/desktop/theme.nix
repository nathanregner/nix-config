{ pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.packages = with pkgs.unstable;
    [
      # nerdfonts is large - just use a subset
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];

  gtk = {
    enable = true;
    theme = {
      # nix build .\#homeConfigurations.nregner@iapetus.config.gtk.theme.package
      # ls result/share/themes
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.unstable.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "compact";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };
  };

  home.pointerCursor = {
    name = "Catppuccin-Mocha-Dark-Cursors";
    package = pkgs.unstable.catppuccin-cursors.mochaDark;
    size = 24;
    gtk.enable = true;
  };

}
