{ config, lib, ... }:
{
  imports = [
    ../nixos/base/nix.nix
    ../nixos/desktop/nix.nix
  ];

  # https://github.com/nix-darwin/nix-darwin/issues/1307
  nix.gc.automatic = lib.mkForce false;
  nix.optimise.automatic = lib.mkForce false;

  # https://github.com/NixOS/nix/issues/4119#issuecomment-1734738812
  nix.settings = {
    sandbox = "relaxed";
    extra-sandbox-paths = [ "/nix/store" ];
  };
  system.systemBuilderArgs = lib.mkIf (config.nix.settings.sandbox == "relaxed") {
    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
    '';
  };
}
