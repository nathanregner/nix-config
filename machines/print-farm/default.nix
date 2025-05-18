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
nodes {
  hostnames = [ "sunlu-s8-0" ];
  modules = [
    # ./hardware/orange-pi-zero2.nix
    ./hardware/raspberry-pi-zero2w.nix
    (
      { pkgs, ... }:
      {
        print-farm.klipper = {
          enable = true;
          configFile = ./klipper/sunlu-s8.cfg;
          productId = "614e";
          vendorId = "1d50";
        };
        environment.systemPackages = [ (pkgs.callPackage ./klipper/firmware { }).flash-sunlu-s8 ];
      }
    )
  ];
}
