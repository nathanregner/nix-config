{ pkgs, ... }:
{
  # Adds to `environment.pathsToLink` the path: `/share/nautilus-python/extensions`
  # needed for nautilus Python extensions to work.
  services.gnome.core-apps.enable = true;

  # https://discourse.nixos.org/t/howto-disable-most-gnome-default-applications-and-what-they-are/13505/11
  environment.gnome.excludePackages = with pkgs; [
    adwaita-icon-theme
    epiphany # web browser
    gnome-backgrounds
    gnome-bluetooth
    gnome-calendar
    gnome-color-manager
    gnome-contacts
    gnome-control-center
    gnome-font-viewer
    gnome-maps
    gnome-menus
    gnome-music
    gnome-shell-extensions
    gnome-system-monitor
    gnome-text-editor
    gnome-themes-extra
    gnome-tour
    gnome-user-docs
    orca
    simple-scan
    yelp
  ];
}
