{
  fetchFromGitHub,
  git,
  nix-update-script,
  rustPlatform,
  stdenv,
  vimUtils,
}:
let
  version = "0.11.0-unstable-2025-02-15";
  src = fetchFromGitHub {
    owner = "saghen";
    repo = "blink.cmp";
    rev = "f22ca35d06b2210ebc84280be94caa11cf2ffe9f";
    fetchSubmodules = false;
    sha256 = "sha256-M/Ui7AuIzF5qM2oI4M2Mz8GgecMJ3VXmJFc0DocUa2k=";
  };
  libExt = if stdenv.hostPlatform.isDarwin then "dylib" else "so";
  blink-fuzzy-lib = rustPlatform.buildRustPackage {
    inherit version src;
    pname = "blink-fuzzy-lib";
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "frizbee-0.1.0" = "sha256-5DWOctWMUTZWSv0VKFXPGZJi73eumXndvqDjk5Pm9JU=";
      };
    };

    nativeBuildInputs = [ git ];

    env = {
      # TODO: remove this if plugin stops using nightly rust
      RUSTC_BOOTSTRAP = true;
    };
  };
in
vimUtils.buildVimPlugin {
  pname = "blink.cmp";
  inherit version src;
  preInstall = ''
    mkdir -p target/release
    ln -s ${blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.${libExt} target/release/libblink_cmp_fuzzy.${libExt}
  '';

  # patches = [
  #   (replaceVars ./force-version.patch { inherit (src) tag; })
  # ];

  doInstallCheck = true;
  nvimRequireCheck = "blink-cmp";

  passthru = {
    updateScript = nix-update-script {
      # attrPath = "blink-cmp.blink-fuzzy-lib";
      extraArgs = [ "--version=branch" ];
    };

    # needed for the update script
    inherit blink-fuzzy-lib;
  };

  meta = {
    description = "Performant, batteries-included completion plugin for Neovim";
    homepage = "https://github.com/saghen/blink.cmp";
  };
}
