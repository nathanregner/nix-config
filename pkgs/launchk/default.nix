{
  sources,
  lib,
  apple-sdk,
  llvmPackages,
  ncurses,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  inherit (sources.launchk) pname version src;
  LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    apple-sdk
  ];

  buildInputs = [
    ncurses
  ];

  patchPhase = ''
    substituteInPlace launchk/src/main.rs \
      --replace-fail 'git_version!()' '"${version}"'
  '';
}
