{ lib, pkgs, outputs, ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./sops.nix
    ./system-utilities.nix
    ./tailscale.nix
    ./users.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };

    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      trusted-users = [ "nregner" ];
      trusted-public-keys =
        [ "builder-name:8HCwoSUcLvQOsrG8WyPTABSgBqK1SGqRsrUqQu1sTSk=" ];
      trusted-substituters = [
        "s3://nregner-nix-binary-cache?region=us-west-2&parallel-compression=true"
      ];
    };
  };

}
