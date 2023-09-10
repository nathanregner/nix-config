NIX_SSHOPTS='-p 10022' nixos-rebuild switch --fast --flake ".#sagittarius" \
  --target-host nregner@localhost \
  --use-remote-sudo 
