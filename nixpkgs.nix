{ inputs, outputs }:
{
  config = {
    allowUnfree = true;
    # Workaround for https://github.com/nix-community/home-manager/issues/2942
    allowUnfreePredicate = _: true;
    permittedInsecurePackages = [
      # TODO: remove once github-runner is updated
      "nodejs-20.20.2"
      "nodejs-slim-20.20.2"
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
