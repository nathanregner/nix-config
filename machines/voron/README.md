## Build Image
Derived from https://github.com/ryan4yin/nixos-rk3588

```shell
nix build .#nixosConfigurations.orangepi5.config.system.build.sdImage
sudo dd bs=8M if=result/nixos.img of=/dev/<...> status=progress
```

### SATA Support

https://drive.google.com/file/d/1jFh3mL3jYYhed7hfY8oHWXuDD3uvurFt/view?usp=drive_link

```shell
wget https://github.com/orangepi-xunlong/orangepi-build/blob/next/external/packages/bsp/rk3588/usr/share/orangepi5/rkspi_loader_sata.img
# commit 4e7198373da2201238099a2f3693a7d025fcc275
sudo dd if=/home/pi/Downloads/rkspi_loader_sata.img of=/dev/mtdblock0 status=progress of=direct && sudo sync
```