nixpkgs: name: systems: packages:
let
  inherit (nixpkgs) lib;
in
lib.genAttrs systems (
  system:
  let
    isSupportedPackage = import ./isSupportedPackage.nix lib system;
    recur =
      set:
      builtins.concatMap (
        value:
        if builtins.isAttrs value && value.recurseForDerivations or false then
          recur value
        else if isSupportedPackage name value then
          [ value ]
        else
          [ ]
      ) (builtins.attrValues set);
  in
  nixpkgs.legacyPackages.${system}.releaseTools.aggregate {
    name = "${name}-${system}";
    constituents = recur packages.${system};
  }
)
