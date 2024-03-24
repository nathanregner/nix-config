# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{ lib, rustPlatform, buildPackages, }:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "hydra-hooks";
    version = "1.0.0";

    # src = lib.sources.sourceFilesBySuffices (lib.cleanSource ./.) [ ".nix" ];
    src = lib.cleanSource ./.;

    postPatch = ''
      ln -sf ${./Cargo.toml} Cargo.toml
      ln -sf ${./Cargo.lock} Cargo.lock
    '';

    cargoLock.lockFile = ./Cargo.lock;

    passthru.devenv = pkg.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs or [ ]
        ++ (with buildPackages; [ openapi-generator-cli ]);
      env = old.env or { } // {
        HYDRA_API = "${buildPackages.hydra_unstable.src}/hydra-api.yaml";
        GENERATE_HYDRA =
          "openapi-generator-cli generate -i $HYDRA_API -g rust -o hydra-client";
      };
    });
  };
in pkg

