{
  lib,
  bintools,
  gcc-arm-embedded,
  gnumake,
  klipper,
  libusb1,
  pkg-config,
  pkgsCross,
  python3,
  stdenv,
  wrapCCWith,
  writeShellApplication,
  ...
}:
let
  firmware = stdenv.mkDerivation {
    name = "klipper-rp2040-firmware";
    inherit (klipper) src version;

    nativeBuildInputs = [
      gnumake
      libusb1
      pkg-config
      python3
      (
        let
          libc = pkgsCross.arm-embedded.newlib-nano;
        in
        wrapCCWith {
          cc = gcc-arm-embedded;
          inherit libc;
          bintools = bintools.override { inherit libc; };
        }
      )
    ];

    configurePhase = ''
      cp ${./rp2040_config} .config
    '';

    postPatch = ''
      patchShebangs .
    '';

    buildPhase = ''
      make -j$NIX_BUILD_CORES out/klipper.uf2 lib/rp2040_flash/rp2040_flash
    '';
    enableParallelBuilding = true;

    installPhase = ''
      mkdir -p $out
      cp lib/rp2040_flash/rp2040_flash $out
      cp out/klipper.uf2 $out
    '';
  };
in
writeShellApplication {
  name = "klipper-flash-rp2040";
  text = ''${firmware}/rp2040_flash ${firmware}/klipper.uf2 "$@"'';
  passthru = {
    inherit firmware;
  };
  meta = {
    platforms = lib.platforms.linux;
  };
}
