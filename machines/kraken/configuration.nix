{ inputs, config, hostname, lib, ... }: {
  imports = [
    inputs.orangepi-nix.nixosModules.zero2
    ../../modules/nixos/server
    ./octoprint.nix
  ];

  nixpkgs.overlays = [ inputs.orangepi-nix.overlays.default ];

  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  networking.hostName = hostname;

  # save on limited sd card space
  nix.settings = {
    keep-derivations = lib.mkForce true;
    keep-outputs = lib.mkForce true;
  };

  users.users.root = {
    password = "root"; # ssh password auth disabled, so whatever :)
  };

  boot = {
    supportedFilesystems = lib.mkForce [ "vfat" "ext4" "ntfs" "cifs" ];
    consoleLogLevel = lib.mkDefault 7;
    initrd = { supportedFilesystems = lib.mkForce [ "vfat" "ext4" ]; };
  };

  sops.defaultSopsFile = ./secrets.yaml;

  # Networking
  sops.secrets.ddns.key = "route53/ddns";
  services.route53-ddns = {
    enable = true;
    domain = "${hostname}.nregner.net";
    ipType = "lan";
    ttl = 60;
    environmentFile = config.sops.secrets.ddns.path;
  };

  sops.secrets.wireless.sopsFile = ./secrets.yaml;
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    environmentFile = config.sops.secrets.wireless.path;
    networks."4Cosands" = {
      priority = 1;
      psk = "@Cosands@";
    };
    networks."REGNERD" = {
      priority = 2;
      psk = "@REGNERD@";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
