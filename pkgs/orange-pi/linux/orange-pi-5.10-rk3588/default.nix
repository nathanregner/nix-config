{ inputs, lib, pkgsBuildBuild, linuxManualConfig, ... }@args:
let inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang;
in with lib;
(linuxManualConfig rec {
  version = "5.10.0";
  modDirVersion = version;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  src = inputs.linux-orange-pi-5-10-rk3588;

  allowImportFromDerivation = true;
  configfile = ./.config;

  # build with Clang for easier cross-compilation
  extraMakeFlags = [
    "LLVM=1"
    "KCFLAGS=-I${clang}/resource-root/include"
    "CROSS_COMPILE=aarch64-linux-gnu-"
  ];
} // (args.argsOverride or { })).overrideAttrs (final: prev: {
  name = "k"; # stay under u-boot path length limit

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  # remove CC=stdenv.cc
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
