{
  sources,
  darwin,
  rustPlatform,
}:
rustPlatform.buildRustPackage (
  sources.launchk
  // {
    cargoLock.lockFile = "${sources.launchk.src}/Cargo.lock";

    nativeBuildInputs = with darwin.apple_sdk; [
      MacOSX-SDK
    ];
  }
)
