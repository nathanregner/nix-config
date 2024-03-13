{ inputs, pkgs }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  nodePkgs = pkgs.unstable.nodePackages_latest;
  node2nixPkgs = import ./node2nix {
    pkgs = pkgs.unstable;
    nodejs = nodePkgs.nodejs;
  };
in
{
  inherit (node2nixPkgs) "@olrtg/emmet-language-server";

  cura5 = pkgs.unstable.callPackage ./cura { };

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  graphql-language-service-cli = node2nixPkgs.graphql-language-service-cli.override {
    nativeBuildInputs = [ pkgs.unstable.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/graphql-lsp" \
      --prefix NODE_PATH : ${nodePkgs.graphql}/lib/node_modules
    '';
  };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon.nix { };

  insync = pkgs.unstable.callPackage ./insync.nix { };

  insync-nautilus = pkgs.unstable.callPackage ./insync-nautilus { };

  harper-ls = pkgs.unstable.callPackage ./harper-ls { inherit sources; };

  joker = pkgs.unstable.buildGoModule (
    sources.joker
    // {
      vendorHash = "sha256-t/28kTJVgVoe7DgGzNgA1sYKoA6oNC46AeJSrW/JetU=";
      preBuild = ''
        go generate ./...
      '';
    }
  );

  jdtls = pkgs.jdt-language-server.overrideAttrs {
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

  klipper-calibrate-shaper = pkgs.callPackage ./klipper/calibrate-shaper.nix { };

  klipper-flash-rp2040 = pkgs.callPackage ./klipper/rp2040.nix { };

  moonraker-develop = (pkgs.unstable.callPackage ./moonraker { inherit inputs; });

  inherit (node2nixPkgs) pin-github-action;

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  sf-mono-nerd-font =
    let
      inherit (sources.sf-mono-nerd-font) pname version src;
    in
    pkgs.unstable.runCommand "${pname}-${version}" { } ''
      mkdir -p $out/share/fonts/${pname}
      cp ${src}/*.otf $out/share/fonts/${pname}

'';

  vtsls = node2nixPkgs."@vtsls/language-server";

  writeBabashkaApplication = pkgs.unstable.callPackage ./write-babashka-application.nix { };
}
