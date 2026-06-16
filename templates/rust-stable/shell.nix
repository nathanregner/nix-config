{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) lib;
  package = pkgs.callPackage ./package.nix { };
in
pkgs.mkShellNoCC {
  inputsFrom = [ package ];
  packages = with pkgs; [
    cargo
    clippy
    rustfmt
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [ ];
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
