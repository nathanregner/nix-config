{ pkgs, lib, ... }:
{
  programs.claude-code.merged-hooks = lib.genAttrs [
    "UserPromptSubmit"
    "PostToolUse"
    "PostToolUseFailure"
    "Notification"
    "Stop"
  ] (_: [ { command = "amux hook"; } ]);

  home.packages = [
    pkgs.local.amux
  ];
}
