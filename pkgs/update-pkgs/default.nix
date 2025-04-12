{
  lib,
  packages,
  stdenv,
  writeBabashkaApplication,
  writeText,
  ...
}:
let
  targets = import ./find-pkgs.nix {
    inherit lib writeText;
    pkgs = packages;
  };
  script = writeBabashkaApplication {
    name = "update-pkgs";
    text = builtins.readFile ./update-pkgs.clj;

    passthru = {
      inherit targets;
      attrs = builtins.attrNames targets;
    };
  };
in
stdenv.mkDerivation {
  name = "nixpkgs-update-script";
  buildCommand = ''
    echo "Not possible to update packages using \`nix-build\`"
    exit 1
  '';
  shellHook = ''
    unset shellHook # do not contaminate nested shells
    ${lib.getExe script} preprocess_cancellation
  '';
  inherit (script) passthru;
}
