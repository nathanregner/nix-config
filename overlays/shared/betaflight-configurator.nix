# https://github.com/NixOS/nixpkgs/issues/305779
# https://github.com/betaflight/betaflight-configurator/issues/3947
prev: pkg:
let
  lib = prev.lib;
  assertVersion =
    version: pkg:
    lib.throwIf (
      version != pkg.version
    ) "${pkg.pname or "???"} has been updated: ${version} -> ${pkg.version}" pkg;
in
(assertVersion "10.10.0" pkg).override {
  nwjs = prev.nwjs.overrideAttrs rec {
    version = "0.84.0";
    src = prev.fetchurl {
      url = "https://dl.nwjs.io/v${version}/nwjs-v${version}-linux-x64.tar.gz";
      hash = "sha256-VIygMzCPTKzLr47bG1DYy/zj0OxsjGcms0G1BkI/TEI=";
    };
  };
}
