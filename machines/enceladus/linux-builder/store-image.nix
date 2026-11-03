{
  config,
  pkgs,
  lib,
  ...
}:
let
  nixStoreFilesystemLabel = "nix-store";
  hostPkgs = config.virtualisation.host.pkgs;
  regInfo = hostPkgs.closureInfo { rootPaths = config.virtualisation.additionalPaths; };
  storeImg =
    pkgs.runCommand "nix-store.img"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.erofs-utils
        ];
      }
      ''
        tar --create \
          --absolute-names \
          --verbatim-files-from \
          --transform 'flags=rSh;s|/nix/store/||' \
          --transform 'flags=rSh;s|~nix~case~hack~[[:digit:]]\+||g' \
          --files-from ${
            pkgs.closureInfo {
              rootPaths = [
                config.system.build.toplevel
                regInfo
              ];
            }
          }/store-paths \
          | mkfs.erofs \
            --quiet \
            --force-uid=0 \
            --force-gid=0 \
            -L ${nixStoreFilesystemLabel} \
            -U eb176051-bd15-49b7-9e6b-462e0b467019 \
            -T 0 \
            --tar=f \
            $out
      '';
in
{
  virtualisation = {
    useNixStoreImage = lib.mkForce false;
    mountHostNixStore = false;

    qemu.drives = [
      {
        name = "nix-store";
        file = "${storeImg}";
        deviceExtraOpts.bootindex = "2";
        driveExtraOpts.format = "raw";
      }
    ];
    fileSystems = {
      "/nix/store" = {
        overlay = {
          lowerdir = [ "/nix/.ro-store" ];
          upperdir = "/nix/.rw-store/upper";
          workdir = "/nix/.rw-store/work";
        };
      };
      "/nix/.ro-store" = {
        device = "/dev/disk/by-label/${nixStoreFilesystemLabel}";
        fsType = "erofs";
        neededForBoot = true;
        options = [ "ro" ];
      };
    };
  };

  # The writable store layer and nix db persist on the root disk, but the store image is replaced
  # whenever the VM config changes. Stale entries then point into the old image, so the db lists
  # paths that are gone and erofs reports "unsupported i_format" for stale overlay lookups. Start
  # from a clean layer whenever the image changes; register-nix-paths reloads the db from regInfo.
  boot.initrd.systemd.services.reset-rw-store = {
    description = "Reset writable Nix store after a store image change";
    requiredBy = [ "rw-sysroot-nix-store.service" ];
    before = [ "rw-sysroot-nix-store.service" ];
    unitConfig = {
      DefaultDependencies = false;
      RequiresMountsFor = "/sysroot/nix";
    };
    serviceConfig.Type = "oneshot";
    script = ''
      [[ "$(cat /proc/cmdline)" =~ regInfo=([^ ]*) ]] || exit 0
      image="''${BASH_REMATCH[1]}"
      marker=/sysroot/nix/.rw-store/image
      if [[ "$(cat "$marker" 2>/dev/null)" != "$image" ]]; then
        echo "store image changed, resetting writable store and nix db"
        rm -rf /sysroot/nix/.rw-store /sysroot/nix/var/nix/db
        mkdir -p /sysroot/nix/.rw-store
        echo "$image" > "$marker"
      fi
    '';
  };
}
