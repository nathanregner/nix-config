{ pkgs, lib, ... }:
{
  programs.claude-code.merged-hooks = lib.genAttrs [
    "Notification"
    "PermissionPrompt"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
    "UserPromptSubmit"
  ] (_: [ { command = "amux hook"; } ]);

  home.packages = [
    pkgs.local.amux
  ];
}
