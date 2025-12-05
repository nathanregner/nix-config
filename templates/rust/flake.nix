{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      fenix,
      flake-parts,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        {
          # https://flake.parts/overlays#consuming-an-overlay
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              fenix.overlays.default
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              rustfmt = {
                enable = true;
                package = pkgs.fenix.complete.rustfmt;
              };
              taplo.enable = true;
            };
          };

          packages =
            let
              toolchain = pkgs.fenix.complete.withComponents [
                "cargo"
                "rustc"
              ];
              rustPlatform = (
                pkgs.makeRustPlatform {
                  cargo = toolchain;
                  rustc = toolchain;
                }
              );
            in
            {
              default = rustPlatform.buildRustPackage {
                pname = "";
                version = "0.1.0";
                src = lib.fileset.toSource {
                  root = ./.;
                  fileset = lib.fileset.unions [
                    ./Cargo.lock
                    ./Cargo.toml
                    ./src
                    ./tests
                  ];
                };

                cargoLock.lockFile = ./Cargo.lock;
              };
            };

          devShells.default =
            let
              toolchain = pkgs.fenix.complete.withComponents [
                "cargo"
                "clippy"
                "rust-analyzer"
                "rust-src"
                "rustfmt"
              ];
            in
            pkgs.mkShell {
              env.RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
              packages = [ toolchain ];
            };
        };

      flake = {
      };
    };
}
