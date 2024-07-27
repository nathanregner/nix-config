{
  sources,
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  elasticsearchHost = "http://127.0.0.1:${toString config.services.elasticsearch.port}";
in
{
  services.elasticsearch = {
    enable = true;
    package = pkgs.unstable.elasticsearch7;
    listenAddress = "0.0.0.0";
    port = 9201;
    extraJavaOptions = [
      "-Xms4G"
      "-Xmx4G"
    ];
    extraConf = ''
      xpack.security.enabled: false
      xpack.security.transport.ssl.enabled: false
      xpack.security.http.ssl.enabled: false
    '';
  };

  services.filebeat = {
    enable = true;
    package = pkgs.unstable.filebeat7;
    inputs = {
      # https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-input-journald.html#filebeat-input-journald-seek
      journald = {
        id = "everything";

        seek = "head";
        # seek = "since";
        # since = "-7d";

        # https://www.elastic.co/guide/en/beats/filebeat/7.17/defining-processors.html
        processors = [
          {
            drop_event = {
              "when.equals.systemd.unit" = "hydra-queue-runner.service";
              "when.gt.syslog.priority" = 5;
            };
          }
        ];
      };
    };
    settings.output.elasticsearch.hosts = [ elasticsearchHost ];

    modules = {
      nginx = {
        access = {
          enabled = true;
          var.paths = [ "/var/log/nginx/access.log*" ];
        };
        error = {
          enabled = true;
          var.paths = [ "/var/log/nginx/error.log*" ];
        };
      };
    };
  };

  services.nregner.metrics.enable = false;

  services.metricbeat = {
    enable = true;
    package = pkgs.unstable.metricbeat7;
    modules = {
      # https://www.elastic.co/guide/en/beats/metricbeat/7.17/metricbeat-module-system.html#_example_configuration_59
      system = {
        metricsets = [
          "cpu"
          "load"
          "memory"
          "network"
          "process"
          "process_summary"
          "uptime"
          "socket_summary"
          "core" # Per CPU core usage
          "diskio" # Disk IO
          "filesystem" # File system usage for each mountpoint
          "fsstat" # File system summary metrics
          "raid" # Raid
          "socket" # Sockets and connection info (linux only)
          # "service" # systemd service information
        ];
        enabled = true;
        period = "10s";
        processes = [ ".*" ];
        cpu.metrics = [
          "percentages"
          "normalized_percentages"
        ];
        core.metrics = [ "percentages" ];
      };
      # https://www.elastic.co/guide/en/beats/metricbeat/7.17/metricbeat-module-docker.html
      docker = {
        metricsets = [
          "container"
          "cpu"
          "diskio"
          "event"
          "healthcheck"
          "info"
          #- "image"
          "memory"
          "network"
          #- "network_summary"
        ];
        enabled = true;
        period = "10s";
        hosts = [ "unix:///var/run/docker.sock" ];
      };
    };
    settings.output.elasticsearch.hosts = [ elasticsearchHost ];
  };

  virtualisation.oci-containers.containers.kibana = rec {
    imageFile = sources.kibana.src;
    image = "${imageFile.imageName}:${imageFile.imageDigest}";
    volumes = [
      (
        let
          kibana = yamlFormat.generate "kibana.yml" {
            "server.publicBaseUrl" = "https://kibana.nregner.net";
            "elasticsearch.hosts" = [ elasticsearchHost ];
          };
        in
        "${kibana}:/usr/share/kibana/config/kibana.yml"
      )
    ];
    extraOptions = [ "--net=host" ];
  };

  nginx.subdomain.kibana = {
    "/" = {
      proxyPass = "http://localhost:5601";
      extraConfig = ''
        allow 192.168.0.0/24;
        allow 100.0.0.0/8;
        deny all;
      '';
    };
  };
}
