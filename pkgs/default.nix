# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ inputs, pkgs }: {
  inherit (inputs.nix-fast-build.outputs.packages.${pkgs.system})
    nix-fast-build;

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  netdata-latest = pkgs.unstable.callPackage ./netdata.nix { };

  # disable xvfb-run tests
  xdot-darwin = (pkgs.unstable.xdot.overridePythonAttrs
    (oldAttrs: { nativeCheckInputs = [ ]; })).overrideAttrs
    (oldAttrs: { doInstallCheck = false; });

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

  klipperPkgs = pkgs.unstable.callPackage ./klipper { };

  insync-nautilus = pkgs.unstable.callPackage ./insync-nautilus { };

  insync = pkgs.unstable.callPackage ./insync.nix { };

  joker = pkgs.unstable.buildGoModule ({
    pname = "joker";
    src = inputs.joker;
    version = inputs.joker.rev;
    vendorHash = "sha256-k17BthjOjZs0WB88AVVIM00HcSZl2S5u8n9eB2NFdrk=";
    preBuild = ''
      go generate ./...
    '';
  });

  jdtls = pkgs.unstable.jdt-language-server.overrideAttrs {
    pname = "jdtls";
    version = "v1.33.0";
    src = pkgs.unstable.fetchFromGitHub {
      owner = "eclipse-jdtls";
      repo = "eclipse.jdt.ls";
      rev = "v1.33.0";
      fetchSubmodules = false;
      sha256 = "sha256-wChyVZ3tY/rTemZYmfdsedRZFL6Y0RGyEvzyIp3HEgk=";
    };
  };
}
