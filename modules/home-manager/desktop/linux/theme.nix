{ config, pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "Colloid-Dark-Compact-Catppuccin";
      package = pkgs.unstable.colloid-gtk-theme.override {
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/themes/colloid-gtk-theme/default.nix#L67
        sizeVariants = [ "compact" ];
        tweaks = [
          "black" # mocha: https://github.com/vinceliuice/Colloid-gtk-theme/issues/167
          "catppuccin"
          "rimless"
        ];
      };
    };
    iconTheme = {
      package = pkgs.unstable.catppuccin-papirus-folders;
      name = "Papirus-Dark";
    };
  };

  home.pointerCursor = {
    package = pkgs.unstable.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
    gtk.enable = true;
  };

  # TODO: upstream?
  /*
    assertions =
    let
      assertThemeInPackage =
        { name, package, ... }:
        path:
        let
          themes = builtins.readDir "${package}/share/${path}";
        in
        {
          assertion = themes.${name} or null == "directory";
          message = ''
            ${name} is not a valid theme:
            ${builtins.concatStringsSep "\n" (builtins.map (theme: " - ${theme}") (builtins.attrNames themes))}
          '';
        };
    in
    [
      (assertThemeInPackage config.gtk.theme "themes")
      (assertThemeInPackage config.gtk.iconTheme "icons")
      (assertThemeInPackage config.home.pointerCursor "icons")
    ];
  */
}
