# TODO: nix-update
{
  lib,
  fetchurl,
  git,
  gitea,
  jq,
  mkRustShell,
  openapi-tools,
  openssl,
  pkg-config,
  remarshal,
  runCommand,
  rustPlatform,
  swagger-codegen3,
  ...
}:
let
  env = {
    RUSTC_BOOTSTRAP = true;

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
            | jq '.basePath="localhost"' \
            | jq '.definitions.Repository.required=["owner", "name"]' \
            > swagger.json

          swagger-codegen3 generate \
            -l openapi-yaml \
            -i swagger.json \
            -o openapi

          remarshal -if yaml -i openapi/openapi.yaml -of json \
            | jq 'del(.paths[][].requestBody.content.["text/plain"])' \
            | openapi-tools filter --path "repos/migrate" --path "repos/search" \
            | jq '.components.schemas.Repository.properties.licenses.nullable=true' \
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
            | openapi-tools filter --path "/user/repos" > $out
        '';
  };

  pkg = rustPlatform.buildRustPackage {
    pname = "github-backup";
    version = "1.0.0";

    src = lib.cleanSource ./.;
    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "progenitor-0.9.1" = "sha256-s8ebaxdCYft2FHwB41hnBrKr1t5OU8g4duc+y/3YkeI=";
        "typify-0.3.0" = "sha256-6seAL8DfQmCgQyFR9IAbzuL8ZJXWd56Kkxcr/Y2yE3A=";
      };
    };

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ openssl ];
    nativeCheckInputs = [ git ];

    inherit env;

    passthru.devShell = mkRustShell {
      inherit env pkg rustPlatform;
    };
  };
in
pkg
