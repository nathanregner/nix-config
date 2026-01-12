{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;

    # Use the Babashka script as the notify hook
    hooks.notify = pkgs.writers.writeBabashka "claude-notify" ./claude-notify.clj;

    settings.hooks.Notification = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "notify";
          }
        ];
      }
    ];
  };
}
