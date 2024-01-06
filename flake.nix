{
  inputs = {
    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nathanregner/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Tools
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    # Themes
    catppuccin-alacritty = {
      url = "github:catppuccin/alacritty";
      flake = false;
    };
    catppuccin-k9s = {
      url = "github:catppuccin/k9s";
      flake = false;
    };
    catppuccin-lazygit = {
      url = "github:catppuccin/lazygit";
      flake = false;
    };
    catppuccin-papirus-folders = {
      url = "github:catppuccin/papirus-folders";
      flake = false;
    };

    # Misc
    # https://github.com/realthunder/FreeCAD/releases
    linux-rockchip = {
      url = "github:armbian/linux-rockchip/rk-5.10-rkr4";
      flake = false;
    };
    mealie = {
      url = "github:nathanregner/mealie-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    orangepi-nix = {
      url = "github:nathanregner/orangepi-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    kamp = {
      url = "github:kyleisah/Klipper-Adaptive-Meshing-Purging";
      flake = false;
    };
    mainsail = {
      url = "github:nathanregner/mainsail/develop";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, nix-darwin, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system} // {
            unstable = nixpkgs-unstable.legacyPackages.${system};
          };
        in import ./pkgs { inherit inputs pkgs; });

      # Devshells for flake development
      devShells = forAllSystems (system:
        let
          config = import ./nixpkgs.nix { inherit inputs outputs; };
          pkgs = import nixpkgs-unstable ({ inherit system; } // config);
        in import ./shells.nix { inherit inputs pkgs; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      # nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      # homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#'
      nixosConfigurations = {
        # Desktop
        iapetus = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/iapetus/configuration.nix ];
        };

        # GE73VR Laptop
        callisto = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/callisto/configuration.nix ];
        };

        # Server
        sagittarius = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/sagittarius/configuration.nix ];
        };

        # Builder VM
        ec2-aarch64 = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/ec2-aarch64/configuration.nix ];
          system = "aarch64-linux";
        };

        # Voron 2.4r2 Klipper machine
        voron = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/voron/configuration.nix ];
          system = "aarch64-linux";
        };
      } // (import ./machines/print-farm { inherit self inputs outputs; });

      darwinConfigurations = {
        "Nathans-MacBook-Pro" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/enceladus/configuration.nix ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#'
      homeConfigurations = {
        "nregner@iapetus" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./machines/iapetus/home.nix ];
        };
        "nregner@callisto" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./machines/callisto/home.nix ];
        };
        "nregner" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./machines/enceladus/home.nix ];
        };
      };

      images = lib.mapAttrs (name: nixosConfiguration:
        let
          inherit (nixosConfiguration) config;
          inherit (config.nixpkgs.hostPlatform) system;
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          iso-installer = inputs.nixos-generators.nixosGenerate {
            inherit system;
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
              {
                environment.etc."nixos/flake".source = self.outPath;
                environment.systemPackages = [
                  # copy system closure so we don't have to download/rebuild on the host
                  config.system.build.toplevel
                  (pkgs.runCommand "install-scripts" { } ''
                    mkdir -p $out/bin
                    cp ${config.system.build.formatScript} $out/bin/disko-format
                    cp ${config.system.build.mountScript} $out/bin/disko-mount
                    cp ${
                      pkgs.writeShellScript "install" ''
                        sudo nixos-install --root /mnt --flake ${self.outPath}#${name}
                      ''
                    } $out/bin/nixos-install-flake
                  '')
                ];
                isoImage.squashfsCompression = "zstd -Xcompression-level 1";
              }
            ];
            format = "install-iso";
          };
        }) nixosConfigurations;

      # https://github.com/zhaofengli/colmena
      colmena = let
        # map nixosConfigurations to deployments: https://github.com/zhaofengli/colmena/issues/60#issuecomment-1510496861
        nixosConfigurations = lib.filterAttrs (name: _:
          builtins.match "sunlu-*" name != null || name == "sagittarius" || name
          == "voron") self.nixosConfigurations;
      in {
        meta = {
          nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
          nodeNixpkgs =
            builtins.mapAttrs (name: value: value.pkgs) nixosConfigurations;
          nodeSpecialArgs =
            builtins.mapAttrs (name: value: value._module.specialArgs)
            nixosConfigurations;
          # https://colmena.cli.rs/unstable/reference/meta.html
          allowApplyAll = false;
          # cat /etc/nix/machines > ./colmena-machines
          machinesFile = ./colmena-machines;
        };
      } // builtins.mapAttrs (name: value: {
        imports = value._module.args.modules;
        # https://colmena.cli.rs/unstable/reference/deployment.html
        # deployment.buildOnTarget = true;
      }) nixosConfigurations;
    };
}
