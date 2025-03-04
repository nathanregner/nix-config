{
  klipper,
  python3,
  writeShellApplication,
}:
writeShellApplication {
  name = "klipper-calibrate-shaper";
  runtimeInputs = [
    (python3.withPackages (ps: [
      ps.numpy
      ps.matplotlib
    ]))
  ];
  text = ''
    python3 ${klipper.src}/scripts/calibrate_shaper.py "$@"
  '';
}
