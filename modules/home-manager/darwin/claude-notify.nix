{ config, ... }:
let
  inherit (config.lib.file) mkFlakeSymlink;
in
{
  home.file.".claude/plugins/claude-notify" = {
    source = mkFlakeSymlink ./claude-notify;
    recursive = true;
  };
}
