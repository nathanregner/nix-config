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

  nix.linux-builder = {
    enable = true;
    maxJobs = 8;

    # comment out for inital setup (pulls vm image via cache.nixos.org)
    # remove /var/lib/darwin-builder/*.img to force a reset
    config = {
      imports = [ ./linux-builder/configuration.nix ];
      config._module.args = {
        inherit
          self
          inputs
          outputs
          sources
          ;
      };
    };
  };

  users = {
    users.builder = {
      uid = 502;
      openssh.authorizedKeys.keys = lib.attrValues self.globals.ssh.allKeys;
    };
    knownUsers = [ "builder" ];
  };

  environment.etc."ssh/sshd_config.d/100-allow-tcp-forwarding".text = ''
    AllowTcpForwarding yes
  '';

  launchd.daemons.linux-builder.serviceConfig = {
    StandardOutPath = "/var/log/darwin-builder.log";
    StandardErrorPath = "/var/log/darwin-builder.log";
  };
}
