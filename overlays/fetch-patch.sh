# usage: ./fetch-patch.sh htop-vim commit/3d7450c9708e6b8102a5608b8405fd121f89de2c
name="$1"
url="https://github.com/NixOS/nixpkgs/$2.patch"
hash=$(nix-prefetch-url "$url")

mkdir -p patches
nixfmt <<EOF >patches/$name.nix
{
  name = "$name";
  url = "$url";
  sha256 = "$hash";
}
EOF
