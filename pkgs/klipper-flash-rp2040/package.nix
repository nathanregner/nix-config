# https://www.klipper3d.org/Measuring_Resonances.html#configure-adxl345-with-pi-pico
{
  lib,
  emptyFile,
  gccStdenv,
  klipper-firmware,
  writeShellApplication,
}:
let
  firmware =
    (klipper-firmware.override {
      mcu = "rp2040";
      firmwareConfig = ./rp2040_config;
      wxGTK32 = emptyFile;
      stdenv = gccStdenv;
    }).overrideAttrs
      {
        enableParallelBuilding = true;

        configurePhase = ''
          cp ${./rp2040_config} .config
        '';

        buildPhase = ''
          make -j$NIX_BUILD_CORES out/klipper.elf lib/rp2040_flash/rp2040_flash
        '';

        installPhase = ''
          mkdir -p $out
          cp lib/rp2040_flash/rp2040_flash $out
          cp out/klipper.elf $out
        '';

        meta = {
          platforms = lib.platforms.linux;
          broken = true; # FIXME
        };
      };
in
writeShellApplication {
  name = "klipper-flash-rp2040";
  text = ''${firmware}/rp2040_flash ${firmware}/klipper.elf "$@"'';
  passthru = {
    inherit firmware;
    inherit (firmware) meta;
  };
}
