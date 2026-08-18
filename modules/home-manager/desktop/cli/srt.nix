{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    mkIf
    types
    ;
  cfg = config.programs.srt;
  settingsFormat = pkgs.formats.json { };
in
{
  options.programs.srt = {
    enable = mkEnableOption "sandbox-runtime (srt)";

    package = mkPackageOption pkgs [ "local" "sandbox-runtime" ] { };

    target = mkOption {
      type = types.str;
      default = "claude/srt.json";
      description = "Path relative to XDG config home the generated srt config is written to.";
    };

    settingsFile = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.xdg.configHome}/${cfg.target}";
      description = "Absolute path to the generated srt config.";
    };

    # https://github.com/anthropic-experimental/sandbox-runtime
    # List-valued options merge across module definitions, so consumers can
    # whitelist additional paths/domains without clobbering the base config.
    settings = mkOption {
      default = { };
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          allowPty = mkOption {
            type = types.bool;
            default = false;
          };
          enableWeakerNestedSandbox = mkOption {
            type = types.bool;
            default = false;
          };
          enableWeakerNetworkIsolation = mkOption {
            type = types.bool;
            default = false;
          };
          allowAppleEvents = mkOption {
            type = types.bool;
            default = false;
          };
          network = mkOption {
            default = { };
            type = types.submodule {
              options = {
                allowedDomains = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                deniedDomains = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                allowUnixSockets = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                allowLocalBinding = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            };
          };
          filesystem = mkOption {
            default = { };
            type = types.submodule {
              options = {
                denyRead = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                allowRead = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                allowWrite = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                denyWrite = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
            };
          };
          ignoreViolations = mkOption {
            type = types.attrsOf (types.listOf types.str);
            default = { };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Set the base config here rather than as option defaults so that
    # list/attrs values merge with consumer definitions instead of being
    # replaced wholesale.
    programs.srt.settings = {
      allowPty = true;

      network.allowedDomains = [
        "*.amazonaws.com"
        "*.awsapps.com"
        "*.clickbank.com"
        "*.clickbank.io"
        "*.github.com"
        "*.npmjs.org"
        "github.com"
        "npmjs.org"
      ];

      filesystem = {
        denyRead = [ "/" ];
        allowRead = [
          "/dev/random"
          "/dev/urandom"
          "/etc"
          "/nix/store"
          "/private/etc"
          "/private/var"
          "/run/current-system/sw/bin"
          "/usr"
          "/var"
          "~/.aws"
          "~/.cache/amux"
          "~/.claude"
          "~/.claude.json"
          "~/.config/git"
          "~/.config/nvim"
          "~/.local/share/nvim/lazy"
          "~/.local/state/nix"
          "~/.nix-profile"
          "~/dev"
        ];
        allowWrite = [
          "~/.cache/amux"
          "~/.claude"
          "~/.claude.json"
          "~/dev"
        ];
      };

      ignoreViolations = {
        "*" = [
          "/usr/bin"
          "/System"
        ];
        "git push" = [ "/usr/bin/nc" ];
        "npm" = [ "/private/tmp" ];
      };
    };

    xdg.configFile.${cfg.target}.source = settingsFormat.generate "srt.json" cfg.settings;
  };
}
