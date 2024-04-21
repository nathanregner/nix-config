{ inputs, pkgs }:
let sources = pkgs.callPackage ../_sources/generated.nix { };
in {
  inherit sources;

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

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

  klipper-tools = pkgs.unstable.callPackage ./klipper { };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon.nix { };

  insync-nautilus = pkgs.unstable.callPackage ./insync-nautilus { };

  insync = pkgs.unstable.callPackage ./insync.nix { };

  joker = pkgs.unstable.buildGoModule (sources.joker // {
    vendorHash = "sha256-k17BthjOjZs0WB88AVVIM00HcSZl2S5u8n9eB2NFdrk=";
    preBuild = ''
      go generate ./...
    '';
  });

  pin-github-action = pkgs.unstable.buildNpmPackage (sources.pin-github-action
    // {
      npmDepsHash = "sha256-UTOPQSQwZZ9U940zz8z4S/eAO9yPX4c1nsTXTlwlUfc=";
      NODE_OPTIONS = "--openssl-legacy-provider";
      dontNpmBuild = true;
    });

  sf-mono-nerd-font = let inherit (sources.sf-mono-nerd-font) pname version src;
  in pkgs.unstable.runCommand "${pname}-${version}" { } ''
    mkdir -p $out/share/fonts/${pname}
    cp ${src}/*.otf $out/share/fonts/${pname}
  '';

  tfautomv =
    pkgs.unstable.callPackage ./tfautomv.nix { source = sources.tfautomv; };

  writeBabashkaApplication =
    pkgs.unstable.callPackage ./write-babashka-application.nix { };
}
