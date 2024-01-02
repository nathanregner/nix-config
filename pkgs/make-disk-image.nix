{ disko, nixosConfig, pkgs, lib
, name ? "${nixosConfig.config.networking.hostName}-disko-images"
, extraPostVM ? "", checked ? false }:
let
  diskoLib = disko.lib.lib;
  vmTools = pkgs.vmTools;
  cleanedConfig = diskoLib.testLib.prepareDiskoConfig nixosConfig.config
    diskoLib.testLib.devices;
  systemToInstall = nixosConfig.extendModules {
    modules = [{
      disko.devices = lib.mkForce cleanedConfig.disko.devices;
      boot.loader.grub.devices =
        lib.mkForce cleanedConfig.boot.loader.grub.devices;
    }];
  };
  dependencies = with pkgs; [
    bash
    coreutils
    gnused
    gptfdisk
    parted # for partprobe
    systemdMinimal
    nix
    util-linux
  ];
  preVM = ''
    ${lib.concatMapStringsSep "\n"
    (disk: "truncate -s ${disk.imageSize} ${disk.name}.raw")
    (lib.attrValues nixosConfig.config.disko.devices.disk)}
  '';
  postVM = ''
    # shellcheck disable=SC2154
    mkdir -p "$out"
    ${lib.concatMapStringsSep "\n"
    (disk: ''mv ${disk.name}.raw "$out"/${disk.name}.raw'')
    (lib.attrValues nixosConfig.config.disko.devices.disk)}
    ${extraPostVM}
  '';
  partitioner = ''
    ${systemToInstall.config.system.build.formatScriptNoDeps}
  '';
  installer = ''
    ${systemToInstall.config.system.build.nixos-install}/bin/nixos-install --system ${systemToInstall.config.system.build.toplevel} --keep-going --no-channel-copy -v --no-root-password --option binary-caches ""
  '';
  QEMU_OPTS = lib.concatMapStringsSep " "
    (disk: "-drive file=${disk.name}.raw,if=virtio,cache=unsafe,werror=report")
    (lib.attrValues nixosConfig.config.disko.devices.disk);
in {
  pure = vmTools.runInLinuxVM (pkgs.runCommand name {
    buildInputs = dependencies;
    inherit preVM postVM QEMU_OPTS;
    memSize = nixosConfig.config.disko.memSize;
  } (let cfg = nixosConfig.config;
  in ''
        ls /dev
        echo ${preVM}
        echo $(ls /)

    disko_devices_dir=$(mktemp -d)
    trap 'rm -rf "$disko_devices_dir"' EXIT
    mkdir -p "$disko_devices_dir"

    ( # disk NIXOS_SD /dev/vda   #
      device='/dev/vda'
      imageSize='2G'
      name='NIXOS_SD'
      type='disk'

      ( # gpt  /dev/vda   #
        device='/dev/vda'
        type='gpt'

        sgdisk \
          --set-alignment=2048 \
          --align-end \
          --new=1:0:-0 \
          --change-name=1:disk-NIXOS_SD-root \
          --typecode=1:8300 \
          /dev/vda
        # ensure /dev/disk/by-path/..-partN exists before continuing
        partprobe /dev/vda
        udevadm trigger --subsystem-match=block
        udevadm settle

        ( # btrfs  /dev/disk/by-partlabel/disk-NIXOS_SD-root  /partition-root #
          device='/dev/disk/by-partlabel/disk-NIXOS_SD-root'
          declare -a extraArgs=('-f')
          declare -a mountOptions=('defaults')
          mountpoint='/partition-root'
          type='btrfs'

          mkfs.btrfs /dev/disk/by-partlabel/disk-NIXOS_SD-root -f
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            btrfs filesystem mkswapfile --size 20M "$MNTPOINT/swapfile"
          btrfs filesystem mkswapfile --size 20M "$MNTPOINT/swapfile1"
          )

          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//home"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"

          )
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//home/user"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"

          )
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//nix"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"

          )
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//rootfs"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"

          )
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//swap"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"
            btrfs filesystem mkswapfile --size 20M "$SUBVOL_ABS_PATH/swapfile"
          btrfs filesystem mkswapfile --size 20M "$SUBVOL_ABS_PATH/rel-path"
          )
          (
            MNTPOINT=$(mktemp -d)
            mount /dev/disk/by-partlabel/disk-NIXOS_SD-root "$MNTPOINT" -o subvol=/
            trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
            SUBVOL_ABS_PATH="$MNTPOINT//test"
            mkdir -p "$(dirname "$SUBVOL_ABS_PATH")"
            btrfs subvolume create "$SUBVOL_ABS_PATH"

          )
          )


        ${installer}
        ls /
  ''));
  impure = diskoLib.writeCheckedBash { inherit checked pkgs; } name ''
    set -efu
    export PATH=${lib.makeBinPath dependencies}
    showUsage() {
    cat <<\USAGE
    Usage: $script [options]

    Options:
    * --pre-format-files <src> <dst>
      copies the src to the dst on the VM, before disko is run
      This is useful to provide secrets like LUKS keys, or other files you need for formating
    * --post-format-files <src> <dst>
      copies the src to the dst on the finished image
      These end up in the images later and is useful if you want to add some extra stateful files
      They will have the same permissions but will be owned by root:root
    * --build-memory <amt>
      specify the ammount of memory that gets allocated to the build vm (in mb)
      This can be usefull if you want to build images with a more involed NixOS config
      By default the vm will get 1024M/1GB
    USAGE
    }

    export out=$PWD
    TMPDIR=$(mktemp -d); export TMPDIR
    trap 'rm -rf "$TMPDIR"' EXIT
    cd "$TMPDIR"

    mkdir copy_before_disko copy_after_disko

    while [[ $# -gt 0 ]]; do
      case "$1" in
      --pre-format-files)
        src=$2
        dst=$3
        cp --reflink=auto -r "$src" copy_before_disko/"$(echo "$dst" | base64)"
        shift 2
        ;;
      --post-format-files)
        src=$2
        dst=$3
        cp --reflink=auto -r "$src" copy_after_disko/"$(echo "$dst" | base64)"
        shift 2
        ;;
      --build-memory)
        regex="^[0-9]+$"
        if ! [[ $2 =~ $regex ]]; then
          echo "'$2' is not a number"
          exit 1
        fi
        build_memory=$2
        shift 1
        ;;
      *)
        showUsage
        exit 1
        ;;
      esac
      shift
    done

    export preVM=${
      diskoLib.writeCheckedBash { inherit pkgs checked; } "preVM.sh" ''
        set -efu
        mv copy_before_disko copy_after_disko xchg/
        ${preVM}
      ''
    }
    export postVM=${
      diskoLib.writeCheckedBash { inherit pkgs checked; } "postVM.sh" postVM
    }
    export origBuilder=${
      pkgs.writeScript "disko-builder" ''
        set -eu
        export PATH=${lib.makeBinPath dependencies}
        for src in /tmp/xchg/copy_before_disko/*; do
          [ -e "$src" ] || continue
          dst=$(basename "$src" | base64 -d)
          mkdir -p "$(dirname "$dst")"
          cp -r "$src" "$dst"
        done
        set -f
        ${partitioner}
        set +f
        for src in /tmp/xchg/copy_after_disko/*; do
          [ -e "$src" ] || continue
          dst=/mnt/$(basename "$src" | base64 -d)
          mkdir -p "$(dirname "$dst")"
          cp -r "$src" "$dst"
        done
        ${installer}
      ''
    }

    build_memory=''${build_memory:-1024}
    QEMU_OPTS=${lib.escapeShellArg QEMU_OPTS}
    QEMU_OPTS+=" -m $build_memory"
    export QEMU_OPTS

    ${pkgs.bash}/bin/sh -e ${vmTools.vmRunCommand vmTools.qemuCommandLinux}
    cd /
  '';
}
