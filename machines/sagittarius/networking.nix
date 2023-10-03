{ config, ... }: {
  networking.hostName = "sagittarius";

  systemd.network = {
    enable = true;
    networks = {
      "10-eth0" = {
        matchConfig.Name = "enp4s0";
        networkConfig = { DHCP = "yes"; };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  sops.secrets.ddns.key = "route53/ddns";
  services.route53-ddns = {
    enable = true;
    domain = "nregner.net";
    ipType = "public";
    ttl = 900;
    environmentFile = config.sops.secrets.ddns.path;
  };
}
