{
  inputs = {
    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Tools
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    joker = {
      url = "github:candid82/joker";
      flake = false;
    };
    lazygit = {
      url = "github:jesseduffield/lazygit";
      flake = false;
    };
    mealie = {
      url = "github:nathanregner/mealie-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
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

    # 3d printing
    kamp = {
      url = "github:kyleisah/Klipper-Adaptive-Meshing-Purging";
      flake = false;
    };
    linux-rockchip = {
      url = "github:armbian/linux-rockchip/rk-5.10-rkr6";
      flake = false;
    };
    orangepi-nix = {
      url = "github:nathanregner/orangepi-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    preprocess-cancellation = {
      url = "github:nathanregner/preprocess_cancellation";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin, home-manager
    , home-manager-unstable, ... }@inputs:
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
      globals = import ./globals.nix { inherit lib; };

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
      overlays = import ./overlays { inherit self inputs; };
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
          system = "x86_64-linux";
        };

        # GE73VR Laptop
        callisto = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/callisto/configuration.nix ];
          system = "x86_64-linux";
        };

        # Server
        sagittarius = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/sagittarius/configuration.nix ];
          system = "x86_64-linux";
        };

        # Voron 2.4r2 Klipper machine
        voron = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/voron/configuration.nix ];
          system = "aarch64-linux";
        };
      } // (import ./machines/print-farm { inherit self inputs outputs; });

      darwinConfigurations = {
        "enceladus" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./machines/enceladus/configuration.nix ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#'
      homeConfigurations = {
        "nregner@iapetus" = home-manager-unstable.lib.homeManagerConfiguration {
          pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./machines/iapetus/home.nix ];
        };
        "nregner@callisto" =
          home-manager-unstable.lib.homeManagerConfiguration {
            pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
            extraSpecialArgs = { inherit inputs outputs; };
            modules = [ ./machines/callisto/home.nix ];
          };
        "nregner" = home-manager-unstable.lib.homeManagerConfiguration {
          pkgs = nixpkgs-unstable.legacyPackages.aarch64-darwin;
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

      hydraJobs = {
        nixosConfigurations =
          (lib.mapAttrs (name: { config, ... }: config.system.build.toplevel)
            nixosConfigurations);

        darwinConfigurations =
          (lib.mapAttrs (name: { config, ... }: config.system.build.toplevel)
            darwinConfigurations);

        homeConfigurations =
          (lib.mapAttrs (name: { activation-script, ... }: activation-script)
            homeConfigurations);
      };
    };
}
