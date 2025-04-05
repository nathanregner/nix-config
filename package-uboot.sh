set -x
dd if=/dev/zero of=rkspi_loader.img bs=1M count=0 seek=16
parted -s rkspi_loader.img mklabel gpt
parted -s rkspi_loader.img unit s mkpart idbloader 64 7167
parted -s rkspi_loader.img unit s mkpart vnvm 7168 7679
parted -s rkspi_loader.img unit s mkpart reserved_space 7680 8063
parted -s rkspi_loader.img unit s mkpart reserved1 8064 8127
parted -s rkspi_loader.img unit s mkpart uboot_env 8128 8191
parted -s rkspi_loader.img unit s mkpart reserved2 8192 16383
parted -s rkspi_loader.img unit s mkpart uboot 16384 32734
dd if=result/idbloader.img of=rkspi_loader.img seek=64 conv=notrunc
dd if=result/u-boot.itb of=rkspi_loader.img seek=16384 conv=notrunc
