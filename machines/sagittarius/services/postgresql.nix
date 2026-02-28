{ config, ... }:
{
  services.postgresql = {
    enable = true;
  };

  services.pgbouncer = {
    enable = true;
    settings = {
      # https://www.pgbouncer.org/config.html
      pgbouncer = {
        unix_socket_dir = "/run/pgbouncer";
        listen_port = 6432;
        pool_mode = "transaction";
      };
    };
  };

  systemd.services.pgbouncer = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.prometheus.exporters.pgbouncer = {
    enable = true;
    connectionString = "postgres:///pgbouncer?host=${config.services.pgbouncer.settings.pgbouncer.unix_socket_dir}&port=${toString config.services.pgbouncer.settings.pgbouncer.listen_port}";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "pgbouncer";
      static_configs = [
        { targets = [ "localhost:${toString config.services.prometheus.exporters.pgbouncer.port}" ]; }
      ];
    }
  ];
}
