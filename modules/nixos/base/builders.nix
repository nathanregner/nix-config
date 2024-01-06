{
  nix = {
    distributedBuilds = true;
    settings = {
      builders-use-substitutes = true;
      trusted-users = [ "nregner" ];
    };

    # 1. manually `sudo ssh` first
    # 2. ensure `sshUser` is in `trusted-users`
    buildMachines = [
      {
        hostName = "iapetus";
        protocol = "ssh";
        sshUser = "nregner";
        system = "x86_64-linux";
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
        maxJobs = 12;
        speedFactor = 2;
      }
      {
        hostName = "m3-linux-builder";
        protocol = "ssh";
        sshUser = "root";
        system = "aarch64-linux";
        supportedFeatures =
          [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-armv8-a" ];
        mandatoryFeatures = [ ];
        maxJobs = 8;
      }
    ];
  };

  programs.ssh.knownHosts = {
    iapetus.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhre0L0AW87qYkI5Os8U2+DS5yvAOnjpEY+Lmn5f0l7";
    sagittarius.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQOaeRY07hRIPpeFYRWoQOzP+toxZjveC5jVHF+vpIj";
    m3-linux-builder.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJBWcxb/Blaqt1auOtE+F8QUWrUotiC5qBJ+UuEWdVCb";
  };
}
