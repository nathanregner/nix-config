# TODO: remove after https://github.com/NixOS/nix/pull/15638
prev: pkg:
pkg.overrideAttrs (old: {
  doCheck = old.doCheck or true && !prev.stdenv.isDarwin;
})
