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
    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin, home-manager
    , deploy-rs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forEachNode = lib.trivial.pipe 5 [
        (lib.lists.range 0)
        (map (n: "kraken-${toString n}"))
        lib.genAttrs
      ];

      machines = [ import ./machines/iapetus import ./machines/callisto ];

      forEachMachine = attr: wrap:
        builtins.map (machine:
          lib.mapAttrs (_: args: (wrap args))
          (if builtins.hasAttr attr machine then
            builtins.getAttr attr machine
          else
            { })) machines;

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
      } // forEachNode (hostname:
        # 3d print farm node
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs nixpkgs hostname; };
          modules = [ ./machines/kraken/configuration.nix ];
          system = "aarch64-linux";
        });

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

      # TODO: Derive from nixosConfigurations
      deploy.nodes = forEachNode (hostname: {
        inherit hostname;
        sshUser = "root";
        fastConnection = false;
        remoteBuild = false;
        profiles.system = {
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            self.nixosConfigurations.${hostname};
        };
      }) // {
        ec2-aarch64 = (let hostname = "ec2-aarch64";
        in {
          inherit hostname;
          fastConnection = false;
          remoteBuild = true;
          sshUser = "root";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos
              self.nixosConfigurations.${hostname};
          };
        });
        voron = (let
          hostname = "voron";
          system = "aarch64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
          # nixpkgs with deploy-rs overlay but force the nixpkgs package
          deployPkgs = import nixpkgs {
            inherit system;
            overlays = [
              deploy-rs.overlay
              (self: super: {
                deploy-rs = {
                  inherit (pkgs) deploy-rs;
                  lib = super.deploy-rs.lib;
                };
              })
            ];
          };
        in {
          inherit hostname;
          fastConnection = false;
          remoteBuild = true;
          sshUser = "nregner";
          profiles.system = {
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos
              self.nixosConfigurations.${hostname};
          };
        });
        sagittarius = (let hostname = "sagittarius";
        in {
          inherit hostname;
          fastConnection = false;
          remoteBuild = true;
          sshUser = "nregner";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.${hostname};
          };
        });
      };

      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
