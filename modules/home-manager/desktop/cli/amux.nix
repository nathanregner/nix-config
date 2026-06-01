{ pkgs, lib, ... }:
{
  programs.claude-code.merged-hooks = lib.genAttrs [
    "Notification"
    "PermissionRequest"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
    "UserPromptSubmit"
  ] (_: [ { command = "amux hook"; } ]);

  home.packages = [
    pkgs.local.amux
  ];
}
