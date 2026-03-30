{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.sops-nix.homeManagerModule ];
  sops.age = {
    # keyFile = lib.mkDefault "${
    #   if pkgs.stdenv.isDarwin then
    #     "${config.home.homeDirectory}/Library/Application Support"
    #   else
    #     config.xdg.configHome
    # }/sops/age/keys.txt";
    sshKeyPaths = lib.mkDefault [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    # generateKey = true;
  };
}
