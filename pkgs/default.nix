{ inputs, pkgs }:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };
  fenix = inputs.fenix.packages.${pkgs.stdenv.system};
  nodePkgs = pkgs.unstable.nodePackages_latest;
  node2nixPkgs = import ./node2nix {
    pkgs = pkgs.unstable;
    nodejs = nodePkgs.nodejs;
  };
in
rec {
  inherit (node2nixPkgs) "@olrtg/emmet-language-server";

  cura5 = pkgs.unstable.callPackage ./cura { inherit sources; };

  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  github-backup = pkgs.unstable.callPackage ./github-backup { inherit fenix openapi-tools; };

  graphql-language-service-cli = node2nixPkgs.graphql-language-service-cli.override {
    nativeBuildInputs = [ pkgs.unstable.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/graphql-lsp" \
      --prefix NODE_PATH : ${nodePkgs.graphql}/lib/node_modules
    '';
  };

  hammerspoon = pkgs.unstable.callPackage ./hammerspoon.nix { inherit sources; };

  insync = pkgs.unstable.callPackage ./insync.nix { };

  insync-nautilus = pkgs.unstable.callPackage ./insync-nautilus { };

  harper-ls = pkgs.unstable.callPackage ./harper-ls { inherit sources; };

  hydra-auto-upgrade = pkgs.unstable.callPackage ./hydra-auto-upgrade { };

  generate-sops-keys = pkgs.unstable.callPackage ./generate-sops-keys.nix { };

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

  orca-slicer = (pkgs.unstable.callPackage ./orca-slicer { inherit sources; });

  openapi-tools = (pkgs.unstable.callPackage ./openapi-tools { });

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
