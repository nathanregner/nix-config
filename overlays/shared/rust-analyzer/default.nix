prev: pkg:
let
  readPatches = root: map (path: root + "/${path}") (builtins.attrNames (builtins.readDir root));
in
pkg.overrideAttrs {
  rust-analyzer-unwrapped = prev.rust-analyzer-unwrapped.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ readPatches ./patches;
  });
}
