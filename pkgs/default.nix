# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ inputs, pkgs }:
{
  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  netdata-latest = pkgs.unstable.callPackage ./netdata.nix { };

  # disable xvfb-run tests
  xdot-darwin = (pkgs.unstable.xdot.overridePythonAttrs
    (oldAttrs: { nativeCheckInputs = [ ]; })).overrideAttrs
    (oldAttrs: { doInstallCheck = false; });

  mainsail-develop = pkgs.callPackage ./mainsail.nix { inherit inputs; };

  moonraker-develop = (pkgs.unstable.moonraker.override (prev: rec {
    python3 = prev.python3.override {
      packageOverrides = self: super:
        let
          preprocess-cancellation =
            inputs.preprocess-cancellation.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in assert prev.python3.pkgs.hasPythonModule preprocess-cancellation; {
          inherit preprocess-cancellation;
        };
      self = python3;
    };
  })).overrideAttrs
    (oldAttrs: { patches = [ ./moonraker-preprocess-cancellation.patch ]; });

  prepare-sd-card = pkgs.writeShellApplication {
    name = "prepare-sd-card";
    runtimeInputs = with pkgs; [ gnutar zstd ];
    text = ''
      tmp=$(mktemp -d)
      img="$tmp/sd-card.img"
      mnt="$tmp/mnt"

      sudo mkdir -p "$mnt"
      unzstd "$1" -o "$img"
      sudo mount -o loop,offset=39845888 "$img" "$mnt"
      sudo mkdir -p "$mnt/etc/ssh/"
      sudo tar -axf "$2" -C "$mnt/etc/ssh/"
      sudo umount "$mnt"

      echo "$tmp"
    '';
  };

  klipper = pkgs.unstable.callPackage ./klipper { };
}

// {
  inherit (pkgs.unstable.callPackage ../machines/print-farm/klipper/firmware
    { })
    klipper-flash-sunlu-s8;
}

