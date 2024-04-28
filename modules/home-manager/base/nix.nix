{ inputs, ... }: {
  # pin the flake registry to flake inputs
  # use the `github` type such that `nix flake lock --override-input nixpkgs "flake:nixpkgs-unstable"` doesn't use a store path
  nix.registry = {
    nixpkgs.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      type = "github";
    };
    nixpkgs-unstable.to = {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs-unstable.rev;
      type = "github";
    };
  };

  # ensure registry sources don't get garbage collected
  xdg.dataFile = {
    "nix/flake-channels/nixpkgs".source = inputs.nixpkgs.sourceInfo.outPath;
    "nix/flake-channels/nixpkgs-unstable".source =
      inputs.nixpkgs-unstable.sourceInfo.outPath;
  };
}
