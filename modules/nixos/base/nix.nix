{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.determinate.nixosModules.default
    ../../common/nix.nix
  ];

  nix = {
    optimise.automatic = true;
  };

  warnings = lib.optional (lib.versionOlder config.nix.package.version pkgs.nix.version) "`nix.package` is outdated (${config.nix.package.version} < ${pkgs.nix.version})";

}
