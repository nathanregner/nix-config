{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secret management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Tools
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix/release-23.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.home-manager.follows = "home-manager";

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    # Misc
    linux-rockchip = {
      url = "github:armbian/linux-rockchip/rk-5.10-rkr4";
      flake = false;
    };

    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
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
      forEachNode = lib.trivial.pipe 4 [
        (lib.lists.range 1)
        (map (n: "kraken-${toString n}"))
        lib.genAttrs
      ];
    in rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system} // {
            # TODO: Don't duplicate overlay?
            unstable = nixpkgs-unstable.legacyPackages.${system};
          };
        in import ./pkgs { inherit inputs pkgs; });

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs-unstable.legacyPackages.${system} // {
            inherit (home-manager.packages.${system}) home-manager;
          };
        in import ./shell.nix { inherit pkgs; });

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
          modules = [ ./machines/iapetus/configuration.nix ];
        };

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
          specialArgs = { inherit self inputs outputs nixpkgs-unstable; };
          modules = [ ./machines/voron/configuration.nix ];
          system = "aarch64-linux";
        };
      } // forEachNode (hostname:
        # 3d print farm node
        lib.nixosSystem {
          specialArgs = { inherit self inputs outputs nixpkgs hostname; };
          modules = [ ./machines/kraken/configuration.nix ];
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
          modules = [ ./home-manager/home.nix ];
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
          fastConnection = true;
          remoteBuild = true;
          sshUser = "root";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos
              self.nixosConfigurations.${hostname};
          };
        });
        voron = (let hostname = "voron";
        in {
          inherit hostname;
          fastConnection = false;
          remoteBuild = true;
          sshUser = "nregner";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos
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
