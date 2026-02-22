prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./0001-feat-mount-.nix-profile.patch
  ];
})
