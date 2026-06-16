{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  inherit (inputs) systems;

  perSystem =
    { system, ... }:
    {
      treefmt = import ./treefmt.nix { fenix = inputs.fenix.packages.${system}; };
    };

  flake = {
    config.config = config;
  };
}
