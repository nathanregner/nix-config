#!/usr/bin/env bash
set -e

mnt=./secrets/mnt
mkdir -p $mnt
sudo umount $mnt || true

rsync -a --rsync-path="sudo rsync" "$1:/etc/ssh/ssh_host_ed25519_key*" ./secrets

unzstd "result/sd-image/nixos-sd-image-23.05.20230725.6dc93f0-aarch64-linux.img.zst" -o secrets/sd-card.img

sudo mount -o loop,offset=39845888 secrets/sd-card.img $mnt
sudo mkdir -p "$mnt/etc/ssh/"
sudo cp ./secrets/ssh_host_ed25519_key* "$mnt/etc/ssh/"
sudo umount $mnt
