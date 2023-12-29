{ inputs, modulesPath, pkgs, ... }: {
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    "${modulesPath}/virtualisation/amazon-image.nix"
    ../../modules/nixos/server
    ../../modules/nixos/server/home-manager.nix
  ];

  ec2.efi = true;

  networking.hostName = "ec2-aarch64";

  # decrypt secrets with KMS
  sops.environment = {
    SOPS_KMS_ARN =
      "arn:aws:kms:us-west-2:544292031362:key/mrk-113644e19fad45cd90597b54635d1058+arn:aws:iam::544292031362:role/nix-builder-role";
  };

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
