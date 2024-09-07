{ inputs }:
inputs.hydra.packages.x86_64-linux.hydra.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./fix-restrict-eval-does-not-allow-access-to-git-flake.patch
    ./feat-add-always_supported_system_types-option.patch
  ];
  checkPhase = "";
})
