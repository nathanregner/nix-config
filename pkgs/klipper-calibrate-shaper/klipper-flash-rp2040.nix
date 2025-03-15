{
  pkgsCross,
  stdenv,
  klipper,
  python3,
  gnumake,
  pkg-config,
  libusb,
  writeShellApplication,
  mkShell,
  wrapCCWith,
  gcc-arm-embedded,
  bintools,
  newlib-nano,
}:
let
  firmware = stdenv.mkDerivation {
    name = "klipper-rp2040-firmware";
    inherit (klipper) src version;

    nativeBuildInputs = [
      python3
      gnumake
      pkg-config
      libusb
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
}
// {
  passthru = {
    inherit firmware;
  };
}
