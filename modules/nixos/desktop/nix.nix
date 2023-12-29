{ inputs, outputs, lib, pkgs, ... }: {
  environment.etc = {
    # "nix/flake-channels/system".source = inputs.self;
    "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
    "nix/flake-channels/nixpkgs-unstable".source = inputs.nixpkgs-unstable;
  };

  nix = {
    # pin the flake registry to flake input
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
    };

    # https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798
    # pin system channels to flake inputs
    nixPath = [
      "nixpkgs=/etc/nix/flake-channels/nixpkgs"
      "nixpkgs-unstable=/etc/nix/flake-channels/nixpkgs-unstable"
    ];

    settings = {
      # keep build dependencies for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;
    };
  };
}
