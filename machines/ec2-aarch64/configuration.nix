{ inputs, modulesPath, lib, pkgs, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ../../common/global
    ./binary-cache.nix
  ];

  ec2.efi = true;

  networking.hostName = "ec2-aarch64";

  # automatically shutdown when inactive
  services.logind.extraConfig = ''
    IdleAction=poweroff
    IdleActionSec=15min
  '';

  # basic system utilities
  environment.systemPackages = with pkgs; [ awscli2 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
