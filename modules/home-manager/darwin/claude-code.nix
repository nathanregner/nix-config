{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;

    settings.hooks.Notification = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = pkgs.writers.writeBabashka "claude-notify" { } ./claude-notify.clj;
          }
        ];
      }
    ];
  };
}
