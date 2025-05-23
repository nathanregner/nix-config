{ lib, pkgs, ... }:
{
  home.packages = with pkgs.unstable; [
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.vitals
    gnomeExtensions.dash-to-panel
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.space-bar

    dconf2nix
  ];

  # Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
  dconf.settings = with lib.hm.gvariant; {
    "com/github/wwmm/easyeffects/streamoutputs/bassenhancer/0" = {
      amount = 6.0;
      bypass = false;
      input-gain = -8.0;
      listen = false;
      output-gain = 0.0;
    };

    "org/gnome/desktop/interface" = {
      clock = "12h";
      clock-format = "12h";
      color-scheme = "prefer-dark";
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      lock-delay = mkUint32 1800;
      lock-enabled = true;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "trayIconsReloaded@selfmade.pl"
        "Vitals@CoreCoding.com"
        "dash-to-panel@jderose9.github.com"
        "sound-output-device-chooser@kgshank.net"
        "space-bar@luchrioh"
      ];
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "Alacritty.desktop"
      ];
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
    };
  };
}
