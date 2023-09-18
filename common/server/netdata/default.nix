{ pkgs, ... }: {
  services.netdata = {
    package = pkgs.netdata-latest;
    config = { global = { "memory mode" = "dbengine"; }; };
  };

  environment.systemPackages = [ pkgs.netdata-latest ];
}
