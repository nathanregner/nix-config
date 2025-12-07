{ stdenvNoCC, udevCheckHook }:
stdenvNoCC.mkDerivation {
  name = "probe-rs-udev-rules";

  dontUnpack = true;

  nativeBuildInputs = [
    udevCheckHook
  ];

  buildPhase = ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/69-probe-rs.rules
  '';
}
