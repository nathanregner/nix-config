{
  self,
  inputs,
  outputs,
  sources,
  pkgs,
  lib,
  ...
}:
{
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
    {
      hostName = "iapetus";
      protocol = "ssh-ng";
      sshUser = "nregner";
      system = "x86_64-linux";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 12;
      speedFactor = 2;
    }
  ];

  nix.linux-builder = {
    enable = true;
    maxJobs = 8;
    # comment out for inital setup (pulls vm image via cache.nixos.org)
    # remove /var/lib/darwin-builder/*.img to force a reset
    package = lib.makeOverridable (
      { modules }:
      let
        inherit (inputs) nixpkgs;
        nixos = nixpkgs.lib.nixosSystem {
          modules =
            [
              "${nixpkgs}/nixos/modules/profiles/nix-builder-vm.nix"
              ./linux-builder/configuration.nix
            ]
            ++ [
              {
                virtualisation = {
                  host = {
                    inherit pkgs;
                  };
                  cores = 8; # TODO: Figure out why this can't be > 8
                  diskSize = lib.mkForce (64 * 1024);
                };
              }
            ];
          specialArgs = {
            inherit
              self
              inputs
              outputs
              sources
              ;
          };
          system = "aarch64-linux";
        };
      in
      nixos.config.system.build.macos-builder-installer
    ) { modules = [ ]; };
  };

  launchd.daemons.linux-builder.serviceConfig = {
    StandardOutPath = "/var/log/darwin-builder.log";
    StandardErrorPath = "/var/log/darwin-builder.log";
  };
}
