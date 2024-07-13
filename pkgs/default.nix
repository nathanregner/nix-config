{ inputs, pkgs }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
in
{
  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon.nix { };

  insync = pkgs.unstable.callPackage ./insync.nix { };

  insync-nautilus = pkgs.unstable.callPackage ./insync-nautilus { };

  joker = pkgs.unstable.buildGoModule (
    sources.joker
    // {
      vendorHash = "sha256-t/28kTJVgVoe7DgGzNgA1sYKoA6oNC46AeJSrW/JetU=";
      preBuild = ''
        go generate ./...
      '';
    }
  );

  klipper-calibrate-shaper = pkgs.callPackage ./klipper/calibrate-shaper.nix { };

  klipper-flash-rp2040 = pkgs.callPackage ./klipper/rp2040.nix { };

  moonraker-develop = (pkgs.unstable.callPackage ./moonraker { inherit inputs; });

  pin-github-action = pkgs.unstable.buildNpmPackage (
    sources.pin-github-action
    // {
      npmDepsHash = "sha256-UTOPQSQwZZ9U940zz8z4S/eAO9yPX4c1nsTXTlwlUfc=";
      NODE_OPTIONS = "--openssl-legacy-provider";
      dontNpmBuild = true;
    }
  );

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  sf-mono-nerd-font =
    let
      inherit (sources.sf-mono-nerd-font) pname version src;
    in
    pkgs.unstable.runCommand "${pname}-${version}" { } ''
      mkdir -p $out/share/fonts/${pname}
      cp ${src}/*.otf $out/share/fonts/${pname}
    '';

  tfautomv = pkgs.unstable.callPackage ./tfautomv.nix { source = sources.tfautomv; };

  writeBabashkaApplication = pkgs.unstable.callPackage ./write-babashka-application.nix { };

  vtsls = pkgs.unstable.callPackage ./vtsls { };

  webrtc-streamer = pkgs.unstable.callPackage ./webrtc-streamer.nix {
    inherit (sources) live555 webrtc-streamer;
  };
}
