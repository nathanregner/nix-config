# https://nixos.wiki/wiki/Go
{
  lib,
  buildGoModule,
  mkShell,
  go,
}:
let
  pkg = buildGoModule {
    pname = "gitea-github-mirror";
    version = "1.0.0";

    src = lib.cleanSource ./.;
    vendorHash = "sha256-xATgfGCNQPpQQJ0g3VQVjxXCG7lmFAJo1CWgU/5OUYg=";
    passthru.devShell = mkShell { packages = pkg.nativeBuildInputs ++ pkg.buildInputs; };
  };
in
pkg
