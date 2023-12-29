{ config, lib, utils, ... }@args:
with lib;
let
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.services.backups;
in {
  options.services.backups = mkOption {
    default = { };
    type = types.attrsOf (types.submodule ({ config, name, ... }: {
      options = {
        paths = mkOption {
          type = types.listOf types.str;
          default = null;
          example = [ "/var/lib/postgresql" "/home/user/backup" ];
        };

        timerConfig = mkOption {
          type = types.attrsOf unitOption;
          default = {
            OnCalendar = "daily";
            Persistent = true;
          };
          description = lib.mdDoc ''
            When to run the backup. See {manpage}`systemd.timer(5)` for details.
          '';
          example = {
            OnCalendar = "00:05";
            RandomizedDelaySec = "5h";
            Persistent = true;
          };
        };

        restic = mkOption {
          type = types.attrsOf (types.submodule ({ config, name, ... }:
            {
              # options = {
              #   enable = mkOption {
              #     type = types.bool;
              #     default = true;
              #   };
              # };
            }));
        };
      };
    }));
  };

  config = lib.mkIf (!lib.matchAttrs cfg { }) {
    sops.secrets.restic-password.key = "restic_password";
    sops.secrets.restic-s3-env.key = "restic/s3_env";
  } // (let
    defaults = {
      s3 = name: {
        repository =
          "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic-${args.config.networking.hostName}/${name}";
        initialize = true;
        passwordFile = args.config.sops.secrets.restic-password.path;
        environmentFile = args.config.sops.secrets.restic-s3-env.path;
      };
    };
    resticJobs = trivial.pipe cfg [
      (attrsets.mapAttrsToList (name:
        { paths, restic ? { }, ... }:
        attrsets.mapAttrs' (type: job: {
          name = "${name}-${type}";
          value = ((defaults.${type} or (_: { })) name) // job // {
            inherit paths;
          };
        }) restic))
      (lists.foldl (acc: attrs: acc // attrs) { })
    ];
  in { services.restic.backups = resticJobs; });
}
