{ pkgs, lib }:
{
  calibrate-shaper = pkgs.callPackage ./calibrate-shaper.nix { };
  flash-rp2040 = pkgs.callPackage ./rp2040.nix { };
  kamp = pkgs.callPackage ./kamp.nix { };
}
