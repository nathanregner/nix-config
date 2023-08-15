# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev:
    import ../pkgs {
      inherit (inputs) nixpkgs nixpkgs-unstable;
      pkgs = final;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # FIXME: hack to bypass "FATAL: Module ahci not found" error
    # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
    makeModulesClosure = x:
      prev.makeModulesClosure (x // { allowMissing = true; });

    # bleeding edge by default
    inherit (final.unstable) octoprint moonraker;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
