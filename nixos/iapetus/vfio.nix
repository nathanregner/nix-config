{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.vfio;
  # https://github.com/virtio-win/kvm-guest-drivers-windows
  win-virtio-iso = pkgs.stdenvNoCC.mkDerivation {
    name = "win-virtio-iso";
    version = pkgs.win-virtio.version;
    src = pkgs.win-virtio;
    buildInputs = [ pkgs.cdrtools ];
    installPhase = ''
      mkisofs -o $out $src
    '';
  };
in {
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO";

  config = {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        "vfio_virqfd"

        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      blacklistedKernelModules = [
        "nouveau" # NVIDIA
      ];

      kernelParams =
        let gpuIDs = [ "10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9" ];
        in [
          # enable IOMMU
          "amd_iommu=on"
        ] ++ optionals cfg.enable [
          # isolate the GPU
          "vfio-pci.ids=${concatStringsSep "," gpuIDs}"
          # fix for using secondary GPU as primary?
          "video=vesafb:off,efifb:off"
        ];
    };

    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };

    environment.systemPackages = with pkgs; [ virt-manager ];

    # mount VFIO drivers in a consistent location
    systemd.tmpfiles.rules =
      [ "L+ /var/lib/libvirt/drivers/win-virtio - - - - ${win-virtio-iso}" ];
  };
}
