{
  flake.modules.nixos.btrfs = {
    # https://discourse.nixos.org/t/no-space-on-btrfs-although-there-is-plenty-of-free-disk-space/76669/3
    systemd.services.btrfs-set-dynamic-reclaim = {
      description = "set dynamic reclain on all btrfs filesystems";
      wantedBy = [ "multi-user.target" ];
      script = /* bash */ ''
        shopt -s failglob
        for root in /sys/fs/btrfs/*-*/allocation/data; do
          echo 1 > "$root/dynamic_reclaim"
          echo 1 > "$root/periodic_reclaim"
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        PrivateNetwork = true;
        ProtectHome = true;
        ProtectSystem = true;
        ReadWritePaths = [ "/sys/fs/btrfs" ];
      };
    };
  };
}
