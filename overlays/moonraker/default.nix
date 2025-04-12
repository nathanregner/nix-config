{ moonraker }:

(moonraker.override (prev: rec {
  python3 = prev.python3.override {
    packageOverrides =
      self: super:
      let
        preprocess-cancellation =
          inputs.preprocess-cancellation.packages.${final.stdenv.hostPlatform.system}.default;
      in
      assert prev.python3.pkgs.hasPythonModule preprocess-cancellation;
      {
        inherit preprocess-cancellation;
      };
    self = python3;
  };
})).overrideAttrs
  (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [
      # TODO: upstream https://github.com/Arksine/moonraker/issues/401
      ./0001-file_manager-Add-config-option-to-rename-duplicate-f.patch
      ./moonraker-preprocess-cancellation.patch
    ];
  })
