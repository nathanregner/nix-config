# TODO: remove after https://github.com/NixOS/nixpkgs/pull/578975
prev: pkg:
let
  patchelf = prev.patchelf.overrideAttrs (oldAttrs: {
    version = "0.19.2-unstable-2026-10-20";
    src = prev.fetchFromGitHub {
      owner = "NixOS";
      repo = "patchelf";
      rev = "3e996dbef1fa0658012f8dd290bddcf0302acade";
      hash = "sha256-+c7LIYKu0pYnG7h1dsEIDs6l4+91Vh/oDrSDARdBK3o=";
    };
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.autoreconfHook ];
  });
in
# only insync-pkg uses stdenvNoCC, which isn't otherwise exposed for overriding
pkg.override {
  stdenvNoCC = prev.stdenvNoCC // {
    mkDerivation =
      args:
      prev.stdenvNoCC.mkDerivation (
        args
        // {
          nativeBuildInputs = [ patchelf ] ++ args.nativeBuildInputs;
          # auto-patchelf crashes on *.debug objects
          preInstall = ''
            find usr -name '*.debug' -type f -delete
          '';
        }
      );
  };
}
