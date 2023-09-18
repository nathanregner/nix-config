{
  imports = [ ./netdata ./route53-ddns.nix ./tailscale-bootstrap.nix ];
  services.tailscale-bootstrap.enable = true;
}
