{
  inputs = {
    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    # hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nathanregner/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tools
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
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
    nvim-lspconfig = {
      url = "path:/home/nregner/dev/github/nvim-lspconfig";
      flake = false;
    };
    conform-nvim = {
      url = "github:stevearc/conform.nvim";
      flake = false;
    };
    freecad = {
      url = "github:realthunder/FreeCAD/LinkMerge";
      flake = false;
    };
    linux-rockchip = {
      url = "github:armbian/linux-rockchip/rk-5.10-rkr4";
      flake = false;
    };
    mealie = {
      url = "github:nathanregner/mealie-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, home-manager, deploy-rs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # FIXME: OrangePi Zero 2 Kernel
      forEachNode = do: { };
      # forEachNode = lib.trivial.pipe 4 [
      #   (lib.lists.range 1)
      #   (map (n: "kraken-${toString n}"))
      #   lib.genAttrs
      # ];
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
        in import ./shells.nix { inherit pkgs; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#'
      nixosConfigurations = {
        iapetus = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/iapetus/configuration.nix ];
        };

        sagittarius = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/sagittarius/configuration.nix ];
        };

        # Builder VM
        ec2-aarch64 = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/ec2-aarch64/configuration.nix ];
          system = "aarch64-linux";
        };

        # Voron 2.4r2 Klipper machine
        voron = lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/voron/configuration.nix ];
          system = "aarch64-linux";
        };
      } // forEachNode (hostname:
        # 3d print farm node
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs nixpkgs hostname; };
          modules = [ ./nixos/kraken/configuration.nix ];
          system = "aarch64-linux";
        });

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#'
      homeConfigurations = {
        "nregner@iapetus" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
            inherit (pkgs) targetPlatform;
          };
          modules = [ ./home-manager/iapetus.nix ];
        };
      };

      # TODO: Derive from nixosConfigurations
      deploy.nodes = forEachNode (hostname: {
        inherit hostname;
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
