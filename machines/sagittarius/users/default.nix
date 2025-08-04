{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.local.users;
in
{
  imports = [
    ./craigslist.nix
    ./factorio.nix
    ./minecraft.nix
  ];

  options.local.users = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule {
        options = {
          backupDir = mkOption {
            type = types.str;
            default = ".local/state/backup";
          };
        };
      }
    );
  };

  config = {
    users.users = builtins.mapAttrs (_name: _cfg': {
      isNormalUser = true;
      openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
      linger = true;
      shell = pkgs.unstable.zsh;
    }) cfg;

    systemd.user.services.nixos-activation.unitConfig.ConditionUser = builtins.map (user: "!${user}") (
      builtins.attrNames cfg
    );

    systemd.tmpfiles.rules = lib.concatLists (
      lib.mapAttrsToList (
        user: cfg':
        let
          inherit (config.users.users.${user}) home;
        in
        [
          "d '${home}/${cfg'.backupDir}' 0770 ${user} - - -"
          "d '/vol/backup/home/${user}' 0770 ${user} - - -"
        ]
      ) cfg
    );

    local.services.backup.paths = builtins.mapAttrs (
      user: cfg':
      let
        inherit (config.users.users.${user}) home;
      in
      {
        paths = [ "${home}/${cfg'.backupDir}" ];
        restic = {
          s3 = { };
        };
      }
    ) cfg;
  };
}
