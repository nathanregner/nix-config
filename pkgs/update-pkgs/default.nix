{
  lib,
  packages,
  writeBabashkaApplication,
  writeText,
  ...
}:
let
  targets = writeText "packages.json" (
    builtins.toJSON (
      import ./find-pkgs.nix {
        inherit lib;
        pkgs = packages;
      }
    )
  );
in
writeBabashkaApplication {
  name = "update-pkgs";
  text = builtins.readFile ./update-pkgs.clj;

  passthru = {
    inherit targets;
    attrs = builtins.attrNames targets;
  };
}
