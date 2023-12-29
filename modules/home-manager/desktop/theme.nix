{ pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.packages = with pkgs.unstable; [
    # nerdfonts is large - use a subset
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    inter
  ];

  # home.pointerCursor = {
  #   name = "Catppuccin-Mocha-Light-Cursors";
  #   package = pkgs.unstable.catppuccin-cursors;
  #   size = 24;
  #   gtk.enable = true;
  # };
}
