{
  services.nexus = {
    enable = false; # FIXME https://github.com/NixOS/nixpkgs/pull/418246
    listenAddress = "0.0.0.0";
    listenPort = 8082;
  };
}
