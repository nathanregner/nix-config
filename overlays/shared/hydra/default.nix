_prev: pkg:
let
  readPatches = root: map (path: root + "/${path}") (builtins.attrNames (builtins.readDir root));
in
pkg.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ (readPatches ./patches);
  # sourceRoot is subprojects/hydra, but patches are generated against the repo root and also touch
  # sibling subprojects (the manual is built from ../../hydra-manual)
  postUnpack = (oldAttrs.postUnpack or "") + ''
    chmod -R u+w "$sourceRoot/../.."
  '';
  patchFlags = [
    "-p1"
    "-d"
    "../.."
  ];
  doCheck = false;
})
