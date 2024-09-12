{
  pkgs,
  lib,
}:
let
  packages = lib.packagesFromDirectoryRecursive {
    callPackage = pkgs.unstable.callPackage;
    directory = ./.;
  };
in
lib.recurseIntoAttrs (
  packages
  // {
    klipper-pkgs = lib.recurseIntoAttrs packages.klipper-pkgs;
  }
)
