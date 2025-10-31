{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      devshell,
      fenix,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
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
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              devshell.overlays.default
              fenix.overlays.default
            ];
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
            pkgs.devshell.mkShell {
              env = [
                {
                  name = "RUST_SRC_PATH";
                  value = "${toolchain}/lib/rustlib/src/rust/library";
                }
              ];
              packages = [
                toolchain
              ];
            };
        };

      flake = {
      };
    };
}
