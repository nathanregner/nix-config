{
  outputs,
  overlays ? [ ],
  system ? null,
}:
{
  config = {
    allowUnfree = true;
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = _: true;
  };

  overlays = [
    outputs.overlays.additions
    outputs.overlays.modifications
    outputs.overlays.unstable-packages
    (_: _: { inherit outputs; })
  ];
}
// (if system != null then { inherit system; } else { })
