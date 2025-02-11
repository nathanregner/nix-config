{
  self,
  inputs,
  outputs,
  config,
  lib,
  ...
}:
{
  nix.linux-builder = {
    enable = true;
    maxJobs = 8;

    # comment out for inital setup (pulls vm image via cache.nixos.org)
    # remove /var/lib/darwin-builder/*.img to force a reset
    config = {
      imports = [ ./linux-builder/configuration.nix ];
      config._module.args = {
        inherit
          self
          inputs
          outputs
          ;
        secrets = {
          tailscale-auth-key = config.sops.secrets.tailscale-auth-key.path;
        };
      };
    };
  };

  users = {
    users.builder = {
      uid = 502;
      openssh.authorizedKeys.keys = lib.attrValues self.globals.ssh.allKeys;
    };
    knownUsers = [ "builder" ];
  };

  networking.wakeOnLan.enable = true;

  environment.etc."ssh/sshd_config.d/100-allow-tcp-forwarding".text = ''
    AllowTcpForwarding yes
  '';

  launchd.daemons.linux-builder.serviceConfig = {
    StandardOutPath = "/var/log/darwin-builder.log";
    StandardErrorPath = "/var/log/darwin-builder.log";
  };

  sops.secrets.tailscale-auth-key = {
    sopsFile = ../../modules/nixos/server/services/secrets.yaml;
    key = "tailscale/builder_key";
    name = "linux-builder/tailscale-auth-key";
  };
}
