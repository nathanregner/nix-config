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
  update-pkgs = pkgs.unstable.callPackage ./update-pkgs { inherit packages; };
}
