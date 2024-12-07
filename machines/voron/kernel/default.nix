{
  linuxManualConfig,
  src,
  ubootTools,
  unzip,
  ...
}:
# TODO: mainline kernel? https://github.com/ryan4yin/nixos-rk3588/issues/71
(linuxManualConfig {
  version = "6.1.84-rockchip-rk3588";
  modDirVersion = "6.1.84";

  inherit src;

  configfile = ./orangepi5_config;

  extraMeta.branch = "6.1";

  # nix eval .\#nixosConfigurations.voron.config.system.build.kernel.config > machines/voron/kernel/config.nix
  # allowImportFromDerivation = true;
  config = import ./config.nix;
}).overrideAttrs
  (old: {
    name = "k"; # dodge uboot length limits
    nativeBuildInputs = old.nativeBuildInputs ++ [
      ubootTools
      unzip
    ];
  })
