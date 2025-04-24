{ inputs, ... }:
{
  nix.settings = {
    # keep build dependencies for direnv GC roots
    keep-derivations = true;
    keep-outputs = true;

    # https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798
    # pin system channels to flake inputs
    nix-path = "nixpkgs=${inputs.nixpkgs-unstable}";
  };
}
