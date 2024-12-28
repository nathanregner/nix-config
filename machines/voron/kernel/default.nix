{
  linuxManualConfig,
  source,
  ubootTools,
  ...
}:
(linuxManualConfig {
  inherit (source) src version;
  modDirVersion = "6.1.84";
  extraMeta.branch = "6.1";

  configfile = ./orangepi5_config;

  # nix eval .\#nixosConfigurations.voron.config.system.build.kernel.config > machines/voron/kernel/config.nix
  # allowImportFromDerivation = true;
  config = import ./config.nix;
}).overrideAttrs
  (old: {
    name = "k"; # dodge uboot length limits
    nativeBuildInputs = old.nativeBuildInputs ++ [ ubootTools ];
  })
