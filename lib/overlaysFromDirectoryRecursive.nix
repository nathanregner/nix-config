lib: root:
let
  processDir =
    dir:
    lib.concatMapAttrs (
      name: type:
      let
        path = dir + "/${name}";
      in
      if type == "directory" then
        let
          defaultNix = path + "/default.nix";
        in
        if builtins.pathExists defaultNix then { ${name} = import defaultNix; } else processDir path
      else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
        { ${lib.removeSuffix ".nix" name} = import path; }
      else
        { }
    ) (builtins.readDir dir);
in
final: prev:
lib.mapAttrs (
  name: overlayFn:
  let
    originalPkg = prev.${name} or null;
  in
  if originalPkg == null then
    builtins.trace "Warning: Package '${name}' not found in nixpkgs, skipping overlay" originalPkg
  else
    overlayFn prev originalPkg
) (processDir root)
