lib: system: name: value:
if lib.isDerivation value then
  let
    isBroken = value.meta.broken or false;
    platforms = value.meta.platforms or [ system ];
    badPlatforms = value.meta.badPlatforms or [ ];
  in
  !isBroken && (builtins.elem system platforms) && !(builtins.elem system badPlatforms)
else
  lib.isFunction value
