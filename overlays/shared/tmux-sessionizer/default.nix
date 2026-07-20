_prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./patches/0001-fix-resolve-relative-worktree-paths-to-absolute.patch
  ];
})
