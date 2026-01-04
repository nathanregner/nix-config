# TODO: upstream https://github.com/Arksine/moonraker/issues/401
prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./0001-file_manager-Add-config-option-to-rename-duplicate-f.patch
  ];
})
