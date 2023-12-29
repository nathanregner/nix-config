{ inputs, outputs, config, pkgs, ... }@args: {
  imports = [ ./builder.nix ];

  nix = {
    distributedBuilds = true;
    settings = {
      builders-use-substitutes = true;
      trusted-users = [ "nregner" ];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];

      # keep build dependencies for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;

      substituters = [
        "http://sagittarius:8080/default?priority=10"
        "https://cache.nixos.org?priority=9"
      ];

      trusted-public-keys =
        [ "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8=" ];
    };

    linux-builder-2 = {
      enable = true;
      # package = pkgs.darwin.linux-builder;
      maxJobs = 12;
      # comment out for inital setup (pulls vm image via cache.nixos.org)
      # remove /var/lib/darwin-builder/*.img to force a reset
      config = import ./linux-builder.nix args;
    };
  };

  launchd.daemons.linux-builder = {
    serviceConfig = {
      StandardOutPath = "/var/log/darwin-builder.log";
      StandardErrorPath = "/var/log/darwin-builder.log";
    };
  };

  nixpkgs = import ../../nixpkgs.nix { inherit inputs outputs; } // {
    hostPlatform = "aarch64-darwin";
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Use a case-sensitive file system for nix builds
  services.nix-daemon.tempDir = "/Volumes/tmp";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  environment.etc = {
    "nix/flake-channels/system".source = inputs.self;
    "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
    "nix/flake-channels/nixpkgs-unstable".source = inputs.nixpkgs-unstable;
    "nix/flake-channels/home-manager".source = inputs.home-manager;
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };
  environment.systemPackages = [ config.services.tailscale.package ];
}
