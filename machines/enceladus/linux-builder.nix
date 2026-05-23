{
  self,
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.linux-builder = {
    enable = true;
    maxJobs = 8;
    supportedFeatures = [
      "benchmark"
      "big-parallel"
      "kvm"
      "nixos-test"
    ];

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

  # Allow user SSH key for linux-builder (in addition to the root-only builder key)
  environment.etc."ssh/ssh_config.d/50-linux-builder.conf".text = ''
    Host linux-builder
      IdentityFile ~/.ssh/id_ed25519
  '';

  launchd.daemons.linux-builder.serviceConfig = {
    StandardOutPath = "/var/log/linux-builder.log";
    StandardErrorPath = "/var/log/linux-builder.log";
  };

  launchd.daemons.linux-builder-time-sync =
    let
      wakeScript = pkgs.writeShellScript "linux-builder-wake" ''
        ${pkgs.openssh}/bin/ssh -o ConnectTimeout=5 -o BatchMode=yes \
          -i /etc/ssh/ssh_host_ed25519_key -o IdentitiesOnly=yes \
          timesync@linux-builder "sudo date -s '@$(date +%s)'" 2>/dev/null || true
      '';
    in
    {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.sleepwatcher}/bin/sleepwatcher"
          "-V"
          "-w"
          "${wakeScript}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/linux-builder-time-sync.log";
        StandardErrorPath = "/var/log/linux-builder-time-sync.log";
      };
    };

  sops.secrets.tailscale-auth-key = {
    sopsFile = ../../modules/nixos/server/services/secrets.yaml;
    key = "tailscale/builder_key";
    name = "linux-builder/tailscale-auth-key";
  };
}
