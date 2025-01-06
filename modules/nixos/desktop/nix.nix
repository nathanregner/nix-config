{ inputs, ... }:
{
  nix.registry = {
    # pin the flake registry to inputs to avoid extra downloads
    nixpkgs.flake = inputs.nixpkgs;
    nixpkgs-stable.flake = inputs.nixpkgs;

    # also pin a "github" entry for use of `nix flake lock --override-input nixpkgs "flake:nixpkgs-git"` in other flakes
    # unlike the above entries, this won't result in a store path in the lockfile
    nixpkgs-git.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs-unstable.rev;
      type = "github";
    };
    nixpkgs-stable-git.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      type = "github";
    };
  };

  nix.settings = {
    # keep build dependencies for direnv GC roots
    keep-derivations = true;
    keep-outputs = true;

    # https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798
    # pin system channels to flake inputs
    nix-path = "nixpkgs=${inputs.nixpkgs-unstable}";
  };
}
