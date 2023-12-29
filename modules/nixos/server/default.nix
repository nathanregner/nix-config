{ lib, ... }: {
  imports = [ ../base ./route53-ddns.nix ./tailscaled-autoconnect.nix ];
  services.tailscaled-autoconnect.enable = lib.mkDefault true;
}
