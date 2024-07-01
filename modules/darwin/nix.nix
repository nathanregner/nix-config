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
  system.systemBuilderArgs = {
    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup (subpath "${builtins.storeDir}"))
    '';
  };
}
