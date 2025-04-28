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
  linux-orangepi-6_1-rk35xx = pkgs.callPackage ./linux-orangepi-6_1-rk35xx/package.nix { };
  update-pkgs = pkgs.unstable.callPackage ./update-pkgs { inherit packages; };
}
