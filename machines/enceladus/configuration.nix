{
  self,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/darwin
    ./linux-builder.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "enceladus";

  users.users.nregner = {
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
  };

  security.pam.enableSudoTouchIdAuth = true;

  services.nregner.hydra-builder.enable = true;

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  environment.systemPackages = [
    pkgs.hydra-auto-upgrade
  ];

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "sagittarius";
      protocol = "ssh-ng";
      sshUser = "nregner";
      system = "x86_64-linux";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 10;
      speedFactor = 1;
    }
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
