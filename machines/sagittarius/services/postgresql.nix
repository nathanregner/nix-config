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
        default_pool_size = 20;
        max_db_connections = config.services.postgresql.settings.max_connections or 100;
        admin_users = "postgres,hydra";
        auth_type = "peer";
        ignore_startup_parameters = "extra_float_digits";
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
