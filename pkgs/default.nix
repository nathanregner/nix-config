{
  pkgs,
  lib,
}:
let
  nodePkgs = pkgs.unstable.nodePackages_latest;
  node2nixPkgs = import ./node2nix {
    pkgs = pkgs.unstable;
    nodejs = nodePkgs.nodejs;
  };
in
lib.recurseIntoAttrs {
  inherit (node2nixPkgs) pin-github-action typescript;

  aws-cli-sso = pkgs.unstable.callPackage ./aws-cli-sso { };

  blink-cmp = pkgs.unstable.callPackage ./blink { };

  emmet-language-server = node2nixPkgs."@olrtg/emmet-language-server";

  flake-registry = pkgs.callPackage ./flake-registry { };

  generate-sops-keys = pkgs.unstable.callPackage ./generate-sops-keys.nix { };

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon { };

  harper-ls = pkgs.unstable.callPackage ./harper-ls { };

  hydra-auto-upgrade = pkgs.unstable.callPackage ./hydra-auto-upgrade { };

  joker = pkgs.unstable.callPackage ./joker { };

  kamp = pkgs.callPackage ./klipper/kamp.nix { };

  klipper-calibrate-shaper = pkgs.callPackage ./klipper/calibrate-shaper.nix { };

  klipper-flash-rp2040 = pkgs.callPackage ./klipper/rp2040.nix { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  scroll-reverser = pkgs.unstable.callPackage ./scroll-reverser { };

  sf-mono-nerd-font = pkgs.unstable.callPackage ./sf-mono-nerd-font { };

  update-pkgs = pkgs.unstable.callPackage ./update-pkgs { };

  vtsls = node2nixPkgs."@vtsls/language-server";

  writeBabashkaApplication = pkgs.unstable.callPackage ./write-babashka-application.nix { };
}
