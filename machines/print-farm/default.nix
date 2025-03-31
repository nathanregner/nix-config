{
  self,
  inputs,
  outputs,
}:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  nodes =
    { hostnames, modules }:
    lib.genAttrs hostnames (
      hostname:
      lib.nixosSystem {
        specialArgs = {
          inherit self inputs outputs;
        };
        modules = [
          ./configuration.nix
          { networking.hostName = hostname; }
        ] ++ modules;
        system = "aarch64-linux";
      }
    );
in
(nodes {
  hostnames = [ "sunlu-s8-0" ];
  modules = [
    # ./hardware/orange-pi-zero2.nix
    ./hardware/raspberry-pi-zero2w.nix
    (
      { pkgs, ... }:
      {
      }
    )
  ];
})
