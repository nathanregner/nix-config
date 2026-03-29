{
  inputs,
  bash,
  coreutils,
  stdenv,
}:
inputs.agent-sandbox.lib.${stdenv.hostPlatform.system}.mkSandbox {
  pkg = bash;
  binName = "bash";
  outName = "bash-sandboxed"; # or whatever alias you'd like
  allowedPackages = [
    coreutils
    # pkgs.which
    # pkgs.git
    # pkgs.ripgrep
    # pkgs.fd
    # pkgs.gnused
    # pkgs.gnugrep
    # pkgs.findutils
    # pkgs.jq
  ]; # bash is allowed by default - it is required by the sandbox
  stateDirs = [ "$HOME/.claude" ];
  stateFiles = [
    "$HOME/.claude.json"
    "$HOME/.claude.json.lock"
  ];
  roStateFiles = [
    "$HOME/.cache"
    # "$HOME/.local/state/nix/profiles"
    "$HOME/.nix-profile"
    # "/nix/store"
  ];
  extraEnv = {
    # PATH = "$PATH";
    CLAUDE_CODE_OAUTH_TOKEN = "$CLAUDE_CODE_OAUTH_TOKEN";
    # GITHUB_TOKEN = "$GITHUB_TOKEN";
  };
}
