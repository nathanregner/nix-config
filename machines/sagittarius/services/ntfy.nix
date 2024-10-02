{ pkgs, config, ... }:
let
  cfg = config.services.ntfy-sh;
in
{
  services.ntfy-sh = {
    enable = true;
    package = pkgs.unstable.ntfy-sh;
    settings = {
      base-url = "ntfy.nregner.net";
      listen-http = 3005;
      attachment-cache-dir = "/var/lib/ntfy";
      attachment-file-size-limit = "1G";
      behind-proxy = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d '${cfg.settings.attachment-cache-dir}' - ${cfg.user} ${cfg.group} - -"
  ];

  nginx.subdomain.ntfy = {
    "/".proxyPass = "http://127.0.0.1:${toString cfg.services.ntfy-sh.settings.listen-http}/";
  };
}
