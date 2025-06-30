{
  lib,
  outputs,
  stdenv,
  writeBabashkaApplication,
  writeText,
}:
let
  targets = import ./find-pkgs.nix {
    inherit lib;
    pkgs = outputs.packages.${stdenv.hostPlatform.system};
  };
in
writeBabashkaApplication {
  name = "update-pkgs";
  text = builtins.readFile ./update_pkgs.clj;

  passthru = {
    targets = writeText "packages.json" (builtins.toJSON targets);
    attrs = builtins.attrNames targets;
  };
}
