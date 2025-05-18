{
  avrdude,
  klipper-firmware,
  writeShellApplication,
}:
let
  avrdudeNoDoc = avrdude.override { docSupport = false; };
  build-klipper-firmware =
    firmwareConfig:
    (klipper-firmware.override {
      avrdude = avrdudeNoDoc;
      inherit firmwareConfig;
    }).overrideAttrs
      (prev: {
        nativeBuildInputs = builtins.filter (pkg: builtins.match "wxwidgets.*" pkg.name == null) prev.nativeBuildInputs;
        patches = prev.patches or [ ] ++ [ ./0001-Add-default-klipper.elf.hex-target.patch ];
        installPhase = ''
          cp out/klipper.elf.hex $out
        '';
      });
in
{
  flash-sunlu-s8 = writeShellApplication {
    name = "klipper-flash-sunlu-s8";
    runtimeInputs = [ avrdudeNoDoc ];
    # https://www.klipper3d.org/Bootloaders.html
    # https://kevintechnology.com/2012/06/15/programming-arduino-mega-using-avrdude.html
    # dump fimrware: avrdude -p m2560 -c stk500v2 -P /dev/ttyUSB0 -b 115200 -F -U flash:r:flash.bin:r
    text = ''
      avrdude -c stk500v2 -p m2560 -P "$1" -b 115200 -F -D -Uflash:w:${(build-klipper-firmware ./sunlu-s8-firmware.cfg)}:i
    '';
  };
}
