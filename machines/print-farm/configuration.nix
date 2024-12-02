{
  self,
  config,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/server
    ./klipper
  ];

  boot = {
    supportedFilesystems = lib.mkForce [
      "vfat"
      "ext4"
      "ntfs"
      "cifs"
    ];
    consoleLogLevel = lib.mkDefault 7;
    initrd = {
      supportedFilesystems = lib.mkForce [
        "vfat"
        "ext4"
      ];
    };
  };

  users.users.root.password = "root";
  services.openssh.settings.PasswordAuthentication = false;

  sops.defaultSopsFile = ./secrets.yaml;

  # keep record of flake source
  environment.etc."nix/flake-channels/system".source = self;

  # Networking
  sops.secrets.wireless.sopsFile = ./secrets.yaml;
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    secretsFile = config.sops.secrets.wireless.path;
    networks."4Cosands" = {
      priority = 1;
      psk = "ext:Cosands";
    };
    networks."REGNERD" = {
      priority = 2;
      psk = "ext:REGNERD";
    };
  };

  sops.secrets.ddns.key = "route53/ddns";
  services.route53-ddns = {
    enable = true;
    domain = "${config.networking.hostName}.print.nregner.net";
    ipType = "lan";
    ttl = 60;
    environmentFile = config.sops.secrets.ddns.path;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
