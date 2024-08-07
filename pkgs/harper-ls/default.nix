# TODO: upstream
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  mkShell,
}:
let
  pkg = rustPlatform.buildRustPackage rec {
    pname = "harper-ls";
    version = "0.9.1";

    src = fetchFromGitHub {
      owner = "elijah-potter";
      repo = "harper";
      rev = "v${version}";
      sha256 = "sha256-Ojx5SpwoUbTdC4Aj4mNf8/ltpTDfL5e5rS260lJ3FZw=";
    };

    # nativeBuildInputs = [ cmake ];

    cargoLock.lockFile = "${src}/Cargo.lock";
  };
in
pkg
