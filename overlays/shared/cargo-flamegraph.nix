# https://github.com/flamegraph-rs/flamegraph/pull/446
prev: pkg:
pkg.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    (prev.fetchpatch {
      url = "https://github.com/flamegraph-rs/flamegraph/commit/f01b812b8030d0786ce45b2e3e43ca410cbc2d14.patch";
      hash = "sha256-19hDHBofEAKIHinGqwvbydtkSyIpbtQfokYlAzIVPhE=";
    })
  ];
})
