prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    (prev.fetchpatch2 {
      url = "https://github.com/msteen/nix-prefetch/pull/34.patch";
      hash = "sha256-r+b04fbO4++RPMINgL5Vfqf3ITHQgukOA1jljTCm5gA=";
    })
  ];
})
