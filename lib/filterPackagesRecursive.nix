# derived from https://github.com/numtide/flake-utils/blob/main/filterPackages.nix
lib:
let
  allSystems = [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
  ];
in
system: packages:
let
  filterAttrsRecursiveCond =
    set:
    builtins.listToAttrs (
      builtins.concatMap (
        name:
        let
          value = set.${name};
        in
        if builtins.isAttrs value && value.recurseForDerivations or false then
          [ (lib.nameValuePair name (filterAttrsRecursiveCond value)) ]
        else if lib.isDerivation value then
          let
            isBroken = value.meta.broken or false;
            platforms = value.meta.platforms or allSystems;
            badPlatforms = value.meta.badPlatforms or [ ];
          in
          if !isBroken && (builtins.elem system platforms) && !(builtins.elem system badPlatforms) then
            [ (lib.nameValuePair name value) ]
          else
            [ ]
        else
          [ ]
      ) (builtins.attrNames set)
    );
in
filterAttrsRecursiveCond packages
