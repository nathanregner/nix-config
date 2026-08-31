{ lib, secrets, ... }:
let
  keysDirectory = "/mnt/secrets";
in
{
  virtualisation.sharedDirectories.tailscale = {
    source = lib.removeSuffix "/tailscale-auth-key" "${secrets.tailscale-auth-key}";
    target = keysDirectory;
  };

  services.tailscaled-autoconnect = {
    enable = true;
    secretPath = "${keysDirectory}/tailscale-auth-key";
  };
}
