{
  pkgs,
  lib,
}:
lib.recurseIntoAttrs {
  aws-cli-sso = pkgs.unstable.callPackage ./aws-cli-sso { };

  blink-cmp = pkgs.unstable.callPackage ./blink { };

  flake-registry = pkgs.callPackage ./flake-registry { };

  generate-sops-keys = pkgs.unstable.callPackage ./generate-sops-keys.nix { };

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon { };

  hydra-auto-upgrade = pkgs.unstable.callPackage ./hydra-auto-upgrade { };

  kamp = pkgs.callPackage ./klipper/kamp.nix { };

  klipper-calibrate-shaper = pkgs.callPackage ./klipper/calibrate-shaper.nix { };

  klipper-flash-rp2040 = pkgs.callPackage ./klipper/rp2040.nix { };

  pin-github-action = pkgs.unstable.callPackage ./pin-github-action { };

  prettierd = pkgs.unstable.callPackage ./prettierd { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  scroll-reverser = pkgs.unstable.callPackage ./scroll-reverser { };

  sf-mono-nerd-font = pkgs.unstable.callPackage ./sf-mono-nerd-font { };

  update-pkgs = pkgs.unstable.callPackage ./update-pkgs { };

  vtsls = pkgs.unstable.callPackage ./vtsls { };

  writeBabashkaApplication = pkgs.unstable.callPackage ./write-babashka-application.nix { };
}
