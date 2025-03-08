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

}
