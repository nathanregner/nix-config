{
  pkgs,
  lib,
  nodePackages_latest,
}:

# TODO: Remove once https://github.com/NixOS/nixpkgs/pull/319501 is merged
assert !(builtins.hasAttr "vtsls" pkgs);

let
  node2nixPkgs = import ../node2nix {
    inherit pkgs;
    inherit (nodePackages_latest) nodejs;
  };
in
node2nixPkgs."@vtsls/language-server"
