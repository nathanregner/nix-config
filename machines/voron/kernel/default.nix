{
  fetchFromGitHub,
  linuxManualConfig,
  ubootTools,
  ...
}:
(linuxManualConfig {
  version = "5.10.160-rockchip-rk3588";
  modDirVersion = "5.10.160";

  # TODO: move to 6.1
  # TODO: nix-update
  src = fetchFromGitHub {
    owner = "armbian";
    repo = "linux-rockchip";
    rev = "709c51c64e1652d4f8c87b1815db86f56d188268";
    fetchSubmodules = false;
    sha256 = "sha256-YZdWNhLopRyaEBojqMLMYEMKV6V0HcFgFmDbRSbBhRo=";
  };

  configfile = ./orangepi5_config;

  extraMeta.branch = "5.10";

  # nix eval .\#nixosConfigurations.voron.config.system.build.kernel.config > machines/voron/kernel/config.nix
  # allowImportFromDerivation = true;
  config = import ./config.nix;
}).overrideAttrs
  (old: {
    name = "k"; # dodge uboot length limits
    nativeBuildInputs = old.nativeBuildInputs ++ [ ubootTools ];
  })
