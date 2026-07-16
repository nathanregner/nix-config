_prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./0001-Use-catppuccin-friendly-palette.patch ];
})
