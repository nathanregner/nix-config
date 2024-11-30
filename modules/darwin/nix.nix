{ config, lib, ... }:
{
  imports = [
    ../nixos/base/nix.nix
    ../nixos/desktop/nix.nix
  ];

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
    user = "root";
  };

  # https://github.com/NixOS/nix/issues/4119#issuecomment-1734738812
  nix.settings.sandbox = "relaxed";
  system.systemBuilderArgs = lib.mkIf (config.nix.settings.sandbox == "relaxed") {
    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
    '';
  };
}
