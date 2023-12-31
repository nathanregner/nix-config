{ self, inputs, outputs }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  nodes = { hostnames, modules }:
    lib.genAttrs hostnames (hostname:
      lib.nixosSystem {
        specialArgs = { inherit self inputs outputs hostname; };
        modules = [ ./configuration.nix ] ++ modules;
        system = "aarch64-linux";
      });
in (nodes {
  hostnames = [ "sunlu-s8-0" ];
  modules = [
    ./hardware/orange-pi-zero2.nix
    ({ pkgs, ... }: {
      print-farm.klipper = {
        enable = true;
        configFile = ./klipper/sunlu-s8.cfg;
        productId = "614e";
        vendorId = "1d50";
      };
      environment.systemPackages = [ pkgs.klipper-flash-sunlu-s8 ];
    })
  ];
})

