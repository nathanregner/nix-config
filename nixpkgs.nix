{ inputs, outputs }:
{
  config = {
    allowUnfree = true;
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = _: true;
  };

  overlays = [
    inputs.devshell.overlays.default
    outputs.overlays.additions
    outputs.overlays.modifications
    outputs.overlays.unstable-packages
    (_: _: { inherit outputs; })
  ];
}
