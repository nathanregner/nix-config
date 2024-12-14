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
  services.displayManager.defaultSession = "hyprland";
  # https://wiki.hyprland.org/Configuring/Multi-GPU/
  services.displayManager.environment = {
    WLR_DRM_DEVICES = lib.concatStringsSep ":" [
      "/dev/dri/by-path/pci-0000:2d:00.0-card" # RTX 2070 (primary)
      "/dev/dri/by-path/pci-0000:24:00.0-card" # GTX 1060 (secondary)
    ];
  };

  # https://wiki.hyprland.org/0.20.1beta/Getting-Started/Installation/
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  security.pam.services.hyprlock = { };

  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "nregner";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  programs.dconf.enable = true;

  # Adds to `environment.pathsToLink` the path: `/share/nautilus-python/extensions`
  # needed for nautilus Python extensions to work.
  services.gnome.core-utilities.enable = true;

  services.udisks2.enable = true;

  programs.gnome-disks.enable = true;

  # Sound
  hardware.pulseaudio.enable = false;
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

  services.nregner.hydra-builder.enable = true;

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
      insync-nautilus
      libmtp
      nautilus-python
      nvtopPackages.nvidia
      virt-manager
    ]);

  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # lazy start with docker.socket
    # extraOptions = "--insecure-registry sagittarius:5000";
    daemon.settings = {
      insecure-registries = [
        "http://sagittarius:5000"
        "http://100.92.148.118:5000"
      ];
    };
    storageDriver = "btrfs";
  };

  # virtualisation.docker.rootless = {
  #   enable = true;
  #   setSocketVariable = true;
  #   # enableOnBoot = false; # lazy start with docker.socket
  #   daemon.settings = { insecure-registries = [ "sagittarius:5000" ]; };
  # };

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
