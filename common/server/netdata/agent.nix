{ pkgs, ... }: {
  services.netdata.configDir."stream.conf" = pkgs.writeText "stream.conf" ''
    [stream]
      enabled = yes
      destination = sagittarius:19999
      api key = tailscale
  '';

  services.netdata = {
    enable = true;
    config = {
      web = {
        mode = "none";
        "accept a streaming request every seconds" = 0;
      };
    };
  };
}

