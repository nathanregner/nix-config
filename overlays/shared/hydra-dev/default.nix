prev: pkg:
let
  readPatches = root: map (path: root + "/${path}") (builtins.attrNames (builtins.readDir root));
  # patches are generated against the repo root and also add docs/tests to sibling subprojects, which
  # the hydra flake's source fileset leaves out. only the runtime changes are needed.
  libOnly =
    patch:
    prev.runCommand (baseNameOf patch) { nativeBuildInputs = [ prev.patchutils ]; } ''
      filterdiff -p1 -i 'subprojects/hydra/lib/*' ${patch} > $out
    '';
in
pkg.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ map libOnly (readPatches ./patches);
  # sourceRoot is subprojects/hydra, but patches are relative to the repo root
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
