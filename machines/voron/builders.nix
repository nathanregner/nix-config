{
  nix = {
    distributedBuilds = true;
    settings = {
      builders-use-substitutes = true;
      trusted-users = [ "nregner" ];
    };

    # 1. manually `sudo ssh` first
    # 2. ensure `sshUser` is in `trusted-users`
    buildMachines = [{
      hostName = "iapetus";
      protocol = "ssh";
      sshUser = "nregner";
      system = "x86_64-linux";
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
      # maxJobs = 16;
      # speedFactor = 100;
    }];
  };
}
