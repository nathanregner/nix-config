{
  options,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    foldl
    getAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkOption
    trivial
    types
    ;

  copyOption = builtins.intersectAttrs {
    _type = null;
    apply = null;
    default = null;
    defaultText = null;
    description = null;
    example = null;
    internal = null;
    readOnly = null;
    relatedPackages = null;
    type = null;
    visible = null;
  };
  resticOptions = mapAttrs (_: copyOption) (
    removeAttrs (options.services.restic.backups.type.getSubOptions [ ]) [ "_module" ]
  );

  cfg = config.local.services.backup;
  systemConfig = config;

  toplevel = [
    "dynamicFilesFrom"
    "paths"
    "pruneOpts"
    "timerConfig"
  ];
in
{
  options.local.services.backup.enable = mkOption {
    default = !(options.virtualisation ? qemu);
  };

  # FIXME: define option to fix sops infrec?

  options.local.services.backup.restic = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        let
          mkMerged = name: overrides: resticOptions.${name} // overrides;
          mkDefault = name: default: resticOptions.${name} // { inherit default; };
          # FIXME
          # mkInherited = name: resticOptions.${name} // { default = config.${name}; };
          mkInherited = name: resticOptions.${name};
          mkReadOnly =
            name: default:
            (lib.trace name (lib.traceVal resticOptions.${name}))
            // {
              inherit default;
              readOnly = true;
            };
        in
        {
          options =
            (
              (
                (getAttrs toplevel resticOptions)
                // (mapAttrs mkDefault {
                  pruneOpts = [
                    "--keep-within 7d"
                    "--keep-within-daily 1m"
                    "--keep-within-weekly 6m"
                    "--keep-within-monthly 1y"
                  ];
                })
              )
            )
            // {
              s3 = mkOption {
                type = types.submodule {
                  options =
                    { }
                    // resticOptions
                    # // (genAttrs toplevel mkInherited)
                    // (mapAttrs mkReadOnly {
                      repository = "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${systemConfig.networking.hostName}/${name}";
                      initialize = true;
                      # passwordFile = systemConfig.sops.secrets.restic-password.path;
                      # environmentFile = systemConfig.sops.secrets.restic-s3-env.path;
                    });
                };
              };
            };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      # https://discourse.nios.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nios-restoring-backups/21819
      local.services.backup.restic.nixos = {
        paths = [ "/var/lib/nixos" ];
        s3 = { };
      };
    }
    (lib.mkIf cfg.enable (
      let
        resticJobs = trivial.pipe cfg.restic [
          (mapAttrsToList (
            name: repositories:
            (mapAttrs' (type: opts: {
              name = lib.traceVal "${name}-${type}";
              value = lib.traceValSeqN 1 opts;
            }) (builtins.removeAttrs repositories toplevel))
          ))
          (foldl (acc: attrs: acc // attrs) { })
        ];
      in
      {
        sops.secrets = {
          restic-password = {
            key = "restic_password";
            group = "restic";
            mode = "0440";
          };
          restic-s3-env = {
            key = "restic/s3_env";
            group = "restic";
            mode = "0440";
          };
        };

        users.groups.restic = {
        };

        services.restic.backups = lib.traceValSeqN 2 resticJobs;
      }
    ))
  ];
}
