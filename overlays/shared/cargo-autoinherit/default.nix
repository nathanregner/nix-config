prev: pkg:
pkg.overrideAttrs (oldAttrs: rec {
  patches = oldAttrs.patches or [ ] ++ [
    ./patches/0001-feat-add-shared-only.patch
    ./patches/0002-feat-add-prune.patch
  ];

  cargoDeps = prev.rustPlatform.fetchCargoVendor {
    inherit (oldAttrs) src;
    inherit patches;
    hash = "sha256-v60k9XqdIL6AZAisOroVRWQlzdKlm+XtF4XBpBV1C9k=";
  };

  doCheck = false;
})
