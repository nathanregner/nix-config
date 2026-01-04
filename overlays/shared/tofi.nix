prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    (prev.fetchpatch2 {
      url = "https://github.com/philj56/tofi/pull/189.patch";
      hash = "sha256-qsXRyNE9x1sSDrCq/LTQY/DTEMwYAJB3U0/dPXX/jw4=";
    })
  ];
})
