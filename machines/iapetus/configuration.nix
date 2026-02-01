{
  inputs,
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
  ]
  ++ (with inputs.self.modules.nixos; [
    niri
  ]);

  sops.defaultSopsFile = ./secrets.yaml;

  # Networking
  networking.hostName = "iapetus";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # Desktop environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    xkb.layout = "us";
    xkb.variant = "";
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "nregner";
    };
    defaultSession = "niri";
    gdm.enable = true;
  };

  security.pam.services.hyprlock = { };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  programs.dconf.enable = true;

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

  services.logind.settings.Login.HandlePowerKey = "suspend";

  local.services.hydra-builder.enable = true;

  services.prometheus-host-metrics.enable = lib.mkDefault true;

  system.hydra-auto-upgrade = {
    enable = true;
    dates = null;
  };

  environment.systemPackages = with pkgs.unstable; [
    android-file-transfer # aft-mtp-mount ~/mnt
    libmtp
    nautilus-python
    networkmanagerapplet
    virt-manager
    xwayland-satellite
    perf
    (pkgs.writeShellScriptBin "sanoid" ''
      ${config.systemd.services.sanoid.serviceConfig.ExecStart} "$@"
    '')
  ];

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
    storageDriver = "overlay2"; # https://github.com/moby/moby/issues/9939
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
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  services.sanoid = {
    enable = true;
    interval = "*:0/15";
    datasets."zroot/data/home" = {
      autoprune = true;
      autosnap = true;
      hourly = 4 * 24;
      daily = 30;
      weekly = 4;
      monthly = 3;
    };
  };

  services.udev.extraRules = ''
    ${builtins.readFile ./probe-rs.rules}
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1337", ATTRS{idProduct}=="1337", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1337", ATTRS{idProduct}=="1337", MODE="0666", GROUP="dialout"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
