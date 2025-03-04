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
packages
// {
  klipper-pkgs = lib.recurseIntoAttrs packages.klipper-pkgs;

  update-pkgs = pkgs.unstable.callPackage ./update-pkgs { inherit packages; };
}
