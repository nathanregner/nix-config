# This module creates a bootable SD card image containing the given NixOS
# configuration. The generated image is MBR partitioned, with a FAT
# /boot/firmware partition, and ext4 root partition. The generated image
# is sized to fit its contents, and a boot script automatically resizes
# the root partition to fit the device on the first boot.
#
# The firmware partition is built with expectation to hold the Raspberry
# Pi firmware and bootloader, and be removed and replaced with a firmware
# build for the target SoC for other board families.
#
# The derivation for the SD image will be placed in
# config.system.build.sdImage

{ config, lib, pkgs, ... }:

with lib;

{
  options.disko.sdImage = {
    disk = mkOption {
      description = lib.mdDoc ''
        Name of the disko disk to use for the SD image.
      '';
    };

    imageName = mkOption {
      default =
        "${config.sdImage.imageBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img";
      description = lib.mdDoc ''
        Name of the generated image file.
      '';
    };

    imageBaseName = mkOption {
      default = "nixos-sd-image";
      description = lib.mdDoc ''
        Prefix of the name of the generated image file.
      '';
    };

    storePaths = mkOption {
      type = with types; listOf package;
      example = literalExpression "[ pkgs.stdenv ]";
      description = lib.mdDoc ''
        Derivations to be included in the Nix store in the generated SD image.
      '';
    };

    populateRootCommands = mkOption {
      example = literalExpression
        "''\${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot''";
      description = lib.mdDoc ''
        Shell commands to populate the ./files directory.
        All files in that directory are copied to the
        root (/) partition on the SD image. Use this to
        populate the ./files/boot (/boot) directory.
      '';
    };

    postBuildCommands = mkOption {
      example = literalExpression
        "'' dd if=\${pkgs.myBootLoader}/SPL of=$img bs=1024 seek=1 conv=notrunc ''";
      default = "";
      description = lib.mdDoc ''
        Shell commands to run after the image is built.
        Can be used for boards requiring to dd u-boot SPL before actual partitions.
      '';
    };

    compressImage = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether the SD image should be compressed using
        {command}`zstd`.
      '';
    };

    expandOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to configure the sd image to expand it's partition on boot.
      '';
    };
  };

  config = {
    disko.sdImage.storePaths = [ config.system.build.toplevel ];

    system.build.diskoSdImage =
      let disk = config.disko.devices.disk.${config.disko.sdImage.disk};
      in pkgs.callPackage
      ({ stdenv, dosfstools, e2fsprogs, mtools, libfaketime, util-linux, zstd }:
        stdenv.mkDerivation {
          name = config.sdImage.imageName;

          nativeBuildInputs =
            [ dosfstools e2fsprogs libfaketime mtools util-linux ]
            ++ lib.optional config.sdImage.compressImage zstd;

          inherit (config.sdImage) imageName compressImage;

          buildCommand = ''
            mkdir -p $out/nix-support $out/sd-image
            export img=$out/sd-image/${config.sdImage.imageName}

            echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
            if test -n "$compressImage"; then
              echo "file sd-image $img.zst" >> $out/nix-support/hydra-build-products
            else
              echo "file sd-image $img" >> $out/nix-support/hydra-build-products
            fi

            imageSize= ${disk.imageSize}
            truncate -s $imageSize $img

            ${config.sdImage.postBuildCommands}

            if test -n "$compressImage"; then
                zstd -T$NIX_BUILD_CORES --rm $img
            fi
          '';
        }) { };

    boot.postBootCommands = lib.mkIf config.sdImage.expandOnBoot ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        set -euo pipefail
        set -x
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
        bootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
        ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';
  };
}
