#!/usr/bin/env nix-shell
#!nix-shell -i bash -p imagemagick

function convert() {
  in=$1
  shift
  magick convert -background none "$in" -resize '64x64^' -gravity center -crop 64x64+0+0 "$@"
}

convert ./nix-snowflake.svg ./logo-color.png
convert ./nix-snowflake.svg -colorspace Gray ./logo-gray.png
convert ./nix-snowflake-white.svg ./logo-white.png
