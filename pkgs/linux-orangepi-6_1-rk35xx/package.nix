{
  pkgs,
  lib,
  fetchFromGitHub,
  linuxManualConfig,
  pkgsCross,
  ubootTools,
  writeShellScriptBin,
  ...
}@args:
let
  extraArgs = builtins.removeAttrs args [
    "pkgs"
    "lib"
    "fetchFromGitHub"
    "linuxManualConfig"
    "pkgsCross"
    "ubootTools"
    "writeShellScriptBin"
  ];
  readConfig = writeShellScriptBin "read-config" ''
    echo "{"
     while IFS='=' read key val; do
       [ "x''${key#CONFIG_}" != "x$key" ] || continue
       no_firstquote="''${val#\"}";
       echo '  "'"$key"'" = "'"''${no_firstquote%\"}"'";'
     done < "${./config}"
     echo "}"
  '';
  mkKernel =
    if (pkgs.stdenv.system == "x86_64-linux") then
      pkgsCross.aarch64-multiplatform.linuxManualConfig
    else
      linuxManualConfig;
in
(mkKernel (
  {
    version = "6.1-rk3588";
    modDirVersion = "6.1.43";
    extraMeta.branch = "6.1";
    src = fetchFromGitHub {
      owner = "orangepi-xunlong";
      repo = "linux-orangepi";
      rev = "fb528a6014381c12a129e4f5e33c8034d46ad25e";
      fetchSubmodules = false;
      sha256 = "sha256-mgbYqNcbUNapVxkE3vN2nRC4kkHGHNbEUSz0IoRyST8=";
    };

    # https://github.com/orangepi-xunlong/orangepi-build/tree/next/external/config/kernel
    configfile = ./config;

    # nix eval --expr "$(nix run .\#linux-orangepi-6_1-rk35xx.passthru.readConfig)" | nixfmt > pkgs/linux-orangepi-6_6-rk35xx/config.nix
    config = import ./config.nix;
  }
  // extraArgs
)).overrideAttrs
  (old: {
    name = "k"; # dodge uboot length limits
    nativeBuildInputs = old.nativeBuildInputs ++ [ ubootTools ];

    passthru = old.passthru // {
      inherit readConfig;
      # FIXME
      # updateScript = ./update.sh;

      devShell = (
        # make O=build nconfig
        # make O=build -j12
        let
          pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
        in
        pkgsCross.mkShell {
          env = {
            ARCH = pkgsCross.stdenv.hostPlatform.linuxArch;
            CROSS_COMPILE = pkgsCross.stdenv.cc.targetPrefix;
            PKG_CONFIG_PATH = lib.concatStringsSep ":" [
              "${pkgs.ncurses.dev}/lib/pkgconfig"
              "${pkgs.openssl.dev}/lib/pkgconfig"
            ];
          };
          packages = [
            pkgs.bc
            pkgs.bison
            pkgs.flex
            pkgs.pkg-config
            pkgs.stdenv.cc
            pkgs.ubootTools
          ];
        }
      );
    };
  })
