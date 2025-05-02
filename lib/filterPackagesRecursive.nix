lib: system: packages:
let
  filterAttrsRecursive =
    set:
    builtins.listToAttrs (
      builtins.concatMap (
        name:
        let
          value = set.${name};
          isSupportedPackage = import ./isSupportedPackage.nix lib system;
        in
        if builtins.isAttrs value && value.recurseForDerivations or false then
          [ (lib.nameValuePair name (filterAttrsRecursive value)) ]
        else if isSupportedPackage name value then
          [ (lib.nameValuePair name value) ]
        else
          [ ]
      ) (builtins.attrNames set)
    );
in
filterAttrsRecursive packages
