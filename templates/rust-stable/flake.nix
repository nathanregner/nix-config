{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      self,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } rec {
      imports = [ inputs.flake-parts.flakeModules.partitions ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
      };

      partitions.dev = {
        extraInputsFlake = ./nix/dev;
        extraInputs = {
          inherit (inputs) flake-parts;
          inherit systems;
        };
        module = {
          imports = [ ./nix/dev/flake-module.nix ];
        };
      };

      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        rec {
          packages = {
            default = pkgs.callPackage ./package.nix { };
          };

          checks = {
            inherit (packages) default;
          };

          devShells.default = pkgs.callPackage ./shell.nix { };
        };

      flake = {
        overlays.default = final: prev: {
        };
      };
    };
}
