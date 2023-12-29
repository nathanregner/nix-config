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
      hostName = "m3-linux-builder";
      protocol = "ssh";
      sshUser = "root";
      system = "aarch64-linux";
      supportedFeatures =
        [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-armv8-a" ];
      mandatoryFeatures = [ ];
      maxJobs = 8;
    }];
  };
}
