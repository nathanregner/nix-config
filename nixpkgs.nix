{ inputs, outputs }:
{
  config = {
    allowUnfree = true;
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = _: true;

    # FIXME: openrgb
    permittedInsecurePackages = [
      "mbedtls-2.28.10"
    ];
  };

  overlays = [
    inputs.devshell.overlays.default
    outputs.overlays.additions
    outputs.overlays.modifications
    outputs.overlays.unstable-packages
    (_: _: { inherit outputs; })
  ];
}
