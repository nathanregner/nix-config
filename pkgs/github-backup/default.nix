# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  fenix,
  fetchurl,
  gitea,
  jq,
  lib,
  makeRustPlatform,
  mkShell,
  openapi-tools,
  openssl,
  pkg-config,
  remarshal,
  runCommand,
  stdenv,
  swagger-codegen3,
}:
let
  rustPlatform = makeRustPlatform rec {
    inherit (fenix.minimal) toolchain;
    rustc = toolchain;
    cargo = toolchain;
  };

  pkg = rustPlatform.buildRustPackage {
    pname = "github-backup";
    version = "1.0.0";

    nativeBuildInputs = [
      pkg-config
      openssl
    ];

    # src = lib.sources.sourceFilesBySuffices (lib.cleanSource ./.) [ ".nix" ];
    src = lib.cleanSource ./.;

    postPatch = ''
      ln -sf ${./Cargo.toml} Cargo.toml
      ln -sf ${./Cargo.lock} Cargo.lock
    '';

    cargoLock.lockFile = ./Cargo.lock;

    passthru.devShell = mkShell {
      inherit (pkg) nativeBuildInputs;
      RUST_SRC_PATH = "${fenix.complete.rust-src}/lib/rustlib/src/rust/library";
      GITEA_OPENAPI =
        let
          inherit (gitea) version src;
        in
        runCommand "gitea-openapi-${version}.json"
          {
            nativeBuildInputs = [
              jq
              openapi-tools
              remarshal
              swagger-codegen3
            ];
          }
          ''
            cat '${src}/templates/swagger/v1_json.tmpl' \
              | jq '.info.version="${version}"' \
              | jq '.basePath="http://localhost"' \
              > swagger.json

            swagger-codegen3 generate \
              -l openapi-yaml \
              -i swagger.json \
              -o openapi
            remarshal -if yaml -i openapi/openapi.yaml -of json \
              | jq 'del(.paths[][].requestBody.content.["text/plain"])' \
              | openapi-tools filter --path "repos/migrate" --path "/repos/search" \
              > $out
          '';

      GITHUB_OPENAPI =
        let
          openapi = fetchurl {
            url = "https://raw.githubusercontent.com/github/rest-api-description/50bf833eb2c1288fb78419d9e4d359fda3c3ccbe/descriptions/api.github.com/api.github.com.json";
            sha256 = "047r4p4sb2qy3d7pj1baqpl6vimbpk8ddjl1cw9wxkny5jzf397x";
          };
        in
        runCommand "github-openapi.json"
          {
            nativeBuildInputs = [
              jq
              openapi-tools
            ];
          }
          ''
            jq 'del(.paths[][].requestBody.content.["application/x-www-form-urlencoded"])' ${openapi} \
              | openapi-tools filter --path "/search/repositories" > $out
          '';

      packages = [
        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-analyzer"
          "rust-src"
          "rustfmt"
        ])
      ];
    };
  };
in
pkg
