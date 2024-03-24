# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{ lib, rustPlatform, buildPackages, pkg-config, openssl, darwin, stdenv
, fetchFromGitHub, fetchgit, cargo-typify }:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "hydra-hooks";
    version = "1.0.0";

    # src = lib.sources.sourceFilesBySuffices (lib.cleanSource ./.) [ ".nix" ];
    src = lib.cleanSource ./.;

    # postPatch = ''
    #   ln -sf ${./Cargo.toml} Cargo.toml
    #   ln -sf ${./Cargo.lock} Cargo.lock
    # '';

    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [ pkg-config openssl ];
    buildInputs = [ openssl ] ++ lib.optionals stdenv.isDarwin
      [ darwin.apple_sdk.frameworks.SystemConfiguration ];

    passthru.devenv = pkg.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs or [ ]
        ++ (with buildPackages; [ openapi-generator-cli rustfmt ]);

      env = old.env or { } // {
        RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";

        HYDRA_API = "${buildPackages.hydra_unstable.src}/hydra-api.yaml";
        GENERATE_HYDRA =
          "openapi-generator-cli generate -i $HYDRA_API -g rust -o hydra-client --library hyper";

        GH_API = fetchgit {
          url = "https://github.com/github/rest-api-description";
          rev = "e5a54606e0754e4d4d2d083c635f86337f93b775";
          hash = "sha256-WQ8JZyAKsEThZd+kL5WT4XuKdM3EF9gIgFqwWxTwC/E=";
          sparseCheckout = [
            "descriptions/api.github.com"
            "descriptions/api.github.com/dereferenced"
          ];
        };
        GENERATE_GH = ''
          openapi-generator-cli generate \
            -i $GH_API/descriptions/api.github.com/api.github.com.json \
            -g rust \
            -o github-client  \
            --library hyper \
            --global-property models,supportingFiles
        '';
      };
    });
  };
in pkg

