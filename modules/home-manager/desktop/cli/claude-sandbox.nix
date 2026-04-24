{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.programs.claude-code.sandbox;

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

  profileEnvVars = lib.foldl' (acc: profile: acc // mkProfileEnvVars profile) { } cfg.awsProfiles;

  defaultAwsEnvVars = lib.optionalAttrs (cfg.awsProfiles != [ ]) {
    AWS_ACCESS_KEY_ID = "$AWS_ACCESS_KEY_ID";
    AWS_SECRET_ACCESS_KEY = "$AWS_SECRET_ACCESS_KEY";
    AWS_SESSION_TOKEN = "$AWS_SESSION_TOKEN";
    AWS_REGION = "$AWS_REGION";
    AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION";
  };

  allStateDirs =
    [
      "$HOME/.claude"
      "$HOME/.cache"
    ]
    ++ cfg.stateDirs
    ++ config.programs.claude-code.settings.permissions.additionalDirectories;

  allStateFiles = [
    "$HOME/.claude.json"
    "$HOME/.claude.json.lock"
  ] ++ cfg.stateFiles;

  allRoStateDirs = [
    "$HOME/.local/state/nix/profiles"
    "$HOME/.nix-profile"
  ] ++ cfg.roStateDirs;

  allExtraEnv =
    {
      PATH = "$HOME/.nix-profile/bin";
      CLAUDE_CODE_OAUTH_TOKEN = "$CLAUDE_CODE_OAUTH_TOKEN";
    }
    // cfg.extraEnv
    // profileEnvVars
    // defaultAwsEnvVars;

  mkSandbox = inputs.agent-sandbox.lib.${pkgs.stdenv.hostPlatform.system}.mkSandbox;

  sandboxedBash = mkSandbox {
    pkg = pkgs.bash;
    binName = "bash";
    outName = "bash-sandboxed";
    inherit (cfg) allowedPackages isolateNixStore;
    stateDirs = allStateDirs;
    stateFiles = allStateFiles;
    roStateDirs = allRoStateDirs;
    extraEnv = allExtraEnv;
  };

  profilesJson = builtins.toJSON cfg.awsProfiles;

  sandboxScript = pkgs.writers.writeNuBin "sandbox-inner"
    {
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        "${lib.makeBinPath cfg.wrapperScriptExtraPackages}"
      ];
    }
    cfg.wrapperScript;

  package =
    if cfg.wrapperScript != null then
      pkgs.writers.writeBashBin "sandbox" ''
        exec ${lib.getExe sandboxScript} --profiles '${profilesJson}' --sandboxed-bash '${lib.getExe sandboxedBash}' "$@"
      ''
    else
      sandboxedBash;

  claudePackage = pkgs.writers.writeBashBin "sandbox-claude" ''
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

    wrapperScript = mkOption {
      type = types.nullOr types.path;
      default = null;
    };

    wrapperScriptExtraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
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
