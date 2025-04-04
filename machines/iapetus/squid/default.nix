{ pkgs, lib, ... }:
{
  # http://localhost:3128/squid-internal-mgr/
  services.squid = {
    enable = true;
    package = pkgs.unstable.squid.overrideAttrs (
      old: lib.addMetaAttrs { knownVulnerabilities = [ ]; } old
    );
    extraConfig = ''
      # TODO
    '';
  };
  # nixpkgs.config.permittedInsecurePackages = [ "squid-7.0.1" ];
  # https://github.com/NixOS/nixpkgs/issues/27535#issuecomment-317719143
  systemd.services.nix-daemon.environment = {
    all_proxy = "http://localhost:3128";
  };
}
