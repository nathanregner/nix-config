{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  cfg = config.programs.claude-code.sandbox;

  mockSecurity = pkgs.writeShellScriptBin "security" ''
    case "$1" in
      find-generic-password|find-internet-password)
        exit 44
        ;;
      *)
        exit 0
        ;;
    esac
  '';

  mkProfileEnvVars =
    profile:
    let
      envName = lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] profile);
    in
    {
      "AWS_${envName}_ACCESS_KEY_ID" = "$AWS_${envName}_ACCESS_KEY_ID";
      "AWS_${envName}_SECRET_ACCESS_KEY" = "$AWS_${envName}_SECRET_ACCESS_KEY";
      "AWS_${envName}_SESSION_TOKEN" = "$AWS_${envName}_SESSION_TOKEN";
      "AWS_${envName}_REGION" = "$AWS_${envName}_REGION";
    };

  allAwsProfiles = cfg.awsProfiles ++ cfg.awsExtraProfiles;

  profileEnvVars = lib.foldl' (acc: profile: acc // mkProfileEnvVars profile) { } allAwsProfiles;

  defaultAwsEnvVars =
    if cfg.awsCredsDir != null then {
      AWS_SHARED_CREDENTIALS_FILE = "$AWS_SHARED_CREDENTIALS_FILE";
      AWS_CONFIG_FILE = "$AWS_CONFIG_FILE";
      AWS_PROFILE = "$AWS_PROFILE";
      AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION";
    }
    else lib.optionalAttrs (allAwsProfiles != [ ]) {
      AWS_ACCESS_KEY_ID = "$AWS_ACCESS_KEY_ID";
      AWS_SECRET_ACCESS_KEY = "$AWS_SECRET_ACCESS_KEY";
      AWS_SESSION_TOKEN = "$AWS_SESSION_TOKEN";
      AWS_REGION = "$AWS_REGION";
      AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION";
    };

  allStateDirs = [
    "$HOME/.claude"
    "$HOME/.cache"
  ]
  ++ cfg.stateDirs
  ++ config.programs.claude-code.settings.permissions.additionalDirectories;

  allStateFiles = [
    "$HOME/.claude.json"
    "$HOME/.claude.json.lock"
  ]
  ++ cfg.stateFiles;

  allRoStateDirs = [
    "$HOME/.local/state/nix/profiles"
    "$HOME/.nix-profile"
  ]
  ++ [
    "$HOME/.config/nvim"
    "$HOME/.local/share/nvim"
    config.home.flakePath
  ]
  ++ lib.optional (cfg.awsCredsDir != null) cfg.awsCredsDir
  ++ cfg.roStateDirs;

  allExtraEnv = {
    COLORTERM = "$COLORTERM";
    EDITOR = "$EDITOR";
    PATH = "${lib.getBin mockSecurity}/bin:$HOME/.nix-profile/bin:/bin:/usr/bin";
  }
  // lib.optionalAttrs (cfg.eksClusters != [ ]) {
    KUBECONFIG = "$HOME/.claude/kube/config";
  }
  // cfg.extraEnv
  // lib.optionalAttrs (cfg.awsCredsDir == null) profileEnvVars
  // defaultAwsEnvVars;

  mkSandbox = inputs.agent-sandbox.lib.${pkgs.stdenv.hostPlatform.system}.mkSandbox;

  sandboxedBash = mkSandbox {
    pkg = pkgs.bash;
    binName = "bash";
    outName = "bash-sandboxed";
    allowedPackages = [ mockSecurity ] ++ cfg.allowedPackages;
    inherit (cfg) isolateNixStore;
    stateDirs = allStateDirs;
    stateFiles = allStateFiles;
    roStateDirs = allRoStateDirs;
    extraEnv = allExtraEnv;
  };

  configJson = builtins.toJSON {
    awsProfiles = cfg.awsProfiles;
    awsExtraProfiles = cfg.awsExtraProfiles;
    awsCredsDir = cfg.awsCredsDir;
    eksClusters = cfg.eksClusters;
    sandboxedBash = lib.getExe sandboxedBash;
  };

  sandboxScript = pkgs.writers.writeNuBin "sandbox-inner" {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath cfg.wrapperScriptExtraPackages}"
    ];
  } cfg.wrapperScript;

  package =
    if cfg.wrapperScript != null then
      pkgs.writers.writeBashBin "sb" ''
        exec ${lib.getExe sandboxScript} --config '${configJson}' "$@"
      ''
    else
      sandboxedBash;

  claudePackage = pkgs.writers.writeBashBin "sb-claude" ''
    exec ${lib.getExe cfg.package} -c '${lib.getExe config.programs.claude-code.package} --dangerously-skip-permissions "$@"' bash "$@"
  '';
in
{
  options.programs.claude-code.sandbox = {
    enable = mkEnableOption "Claude Code sandbox";

    stateDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    stateFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    roStateDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };

    allowedPackages = mkOption {
      type = types.listOf types.package;
      default = [ pkgs.coreutils ];
    };

    isolateNixStore = mkOption {
      type = types.bool;
      default = false;
    };

    awsProfiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    awsExtraProfiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    eksClusters = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            profile = mkOption { type = types.str; };
            cluster = mkOption { type = types.str; };
            alias = mkOption { type = types.str; };
            region = mkOption {
              type = types.str;
              default = "us-west-2";
            };
          };
        }
      );
      default = [ ];
    };

    computedExtraEnv = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      default = allExtraEnv;
    };

    wrapperScript = mkOption {
      type = types.nullOr types.path;
      default = null;
    };

    wrapperScriptExtraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    awsCredsDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory containing cached AWS credentials JSON files (one per profile)";
    };

    sandboxedBash = mkOption {
      type = types.package;
      readOnly = true;
      default = sandboxedBash;
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      default = package;
    };

    claudePackage = mkOption {
      type = types.package;
      readOnly = true;
      default = claudePackage;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
      cfg.claudePackage
    ];
  };
}
