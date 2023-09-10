{ config, ... }: {
  networking.hostName = "voron";

  systemd.network = {
    enable = true;
    networks = {
      "10-eth0" = {
        matchConfig.Name = "end1";
        networkConfig = { DHCP = "yes"; };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

  sops.secrets.ddns.key = "route53-ddns/env";
  services.route53-ddns = {
    enable = true;
    domain = "voron.nregner.net";
    ipType = "lan";
    ttl = 60;
    environmentFile = config.sops.secrets.ddns.path;
  };
}
