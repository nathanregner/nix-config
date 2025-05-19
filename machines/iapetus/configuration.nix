{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/desktop
    ./hardware-configuration.nix
    ./windows-vm
    ./zsa.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  # Networking
  networking.hostName = "iapetus";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  services.blueman.enable = true;

  # Desktop environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    xkb.layout = "us";
    xkb.variant = "";
  };

  programs.hyprland = {
    enable = true;
    package = pkgs.unstable.hyprland;
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "nregner";
    };

    defaultSession = "hyprland";

    environment = {
      # https://wiki.hyprland.org/Configuring/Multi-GPU/
      WLR_DRM_DEVICES = lib.concatStringsSep ":" [
        "/dev/dri/by-path/pci-0000:2d:00.0-card" # RTX 2070 (primary)
        "/dev/dri/by-path/pci-0000:24:00.0-card" # GTX 1060 (secondary)
      ];
    };

    # https://wiki.hyprland.org/0.20.1beta/Getting-Started/Installation/
    sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.unstable.kdePackages.sddm;
    };
  };

  catppuccin.sddm.enable = true;

  security.pam.services.hyprlock = { };

  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  programs.dconf.enable = true;

  # Adds to `environment.pathsToLink` the path: `/share/nautilus-python/extensions`
  # needed for nautilus Python extensions to work.
  services.gnome.core-apps.enable = true;

  services.udisks2.enable = true;

  programs.gnome-disks.enable = true;

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Misc
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  services.logind.powerKey = "suspend";

  local.services.hydra-builder.enable = true;

  services.prometheus-host-metrics.enable = lib.mkDefault true;

  system.hydra-auto-upgrade = {
    enable = true;
    dates = null;
  };

  # https://nixos.wiki/wiki/CCache#Derivation_CCache_2
  environment.systemPackages =
    [ config.boot.kernelPackages.perf ]
    ++ (with pkgs.unstable; [
      android-file-transfer # aft-mtp-mount ~/mnt
      libmtp
      nautilus-python
      networkmanagerapplet
      nvtopPackages.nvidia
      podman-compose
      virt-manager
    ]);

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    dockerCompat = true;
  };

  services.printing.enable = true;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 1; # no swap, let it get pretty full...
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  services.snapper = {
    snapshotInterval = "*:0/15";
    persistentTimer = true;
    # snapper -c home <...>
    # https://wiki.archlinux.org/title/Snapper
    # https://doc.opensuse.org/documentation/leap/reference/html/book-reference/cha-snapper.html#sec-snapper-clean-up-timeline
    configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "nregner" ];
      TIMELINE_CLEANUP = true;
      TIMELINE_CREATE = true;
      TIMELINE_MIN_AGE = 24 * 60 * 60;
      TIMELINE_LIMIT_DAILY = 7;
    };
  };

  services.udev.extraRules = builtins.readFile ./probe-rs.rules;

  services.ollama = {
    enable = true;
  };
  nixpkgs.config.cudaSupport = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
