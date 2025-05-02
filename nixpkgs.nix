{ outputs }:
{
  config = {
    allowUnfree = true;
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = (_: true);
  };

  overlays = [
    outputs.overlays.modifications
    outputs.overlays.unstable-packages

    # TODO
    # (final: prev: { local = packages; })
  ];
}
