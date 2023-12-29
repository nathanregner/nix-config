{ pkgs, ... }: {
  services.netdata.enable = true;

  # https://community.netdata.cloud/t/disable-cloud-nags/2985/4
  systemd.tmpfiles.rules = [
    "L+ /var/lib/netdata/cloud.d/cloud.conf - - - - ${
      pkgs.writeTextFile {
        name = "cloud.conf";
        text = ''
          [global]
            enabled = no
        '';
      }
    }"
  ];

  # https://learn.netdata.cloud/docs/streaming/streaming-configuration-reference#api_key-and-machine_guid-sections
  services.netdata.configDir."stream.conf" = pkgs.writeText "stream.conf" ''
    [stream]
      # This won't stream by itself, except if the receiver is a sender too, which is possible in netdata model.
      enabled = no
      enable compression = yes

    [tailscale]
      enabled = yes
      default memory mode = dbengine
      allow from = 100.*
  '';
}
