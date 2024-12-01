{
  inputs = {
    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
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

    # Tools
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    hydra-sentinel = {
      url = "github:nathanregner/hydra-sentinel";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Desktop
    catppuccin-nix.url = "github:catppuccin/nix";
    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nixpkgs-wayland = {
    #   url = "github:nix-community/nixpkgs-wayland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # 3d printing
    orangepi-nix = {
      url = "github:nathanregner/orangepi-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # misc
    clojure-lsp = {
      # https://github.com/clojure-lsp/clojure-lsp/actions/workflows/nix.yml?query=is%3Asuccess
      url = "github:clojure-lsp/clojure-lsp/074aed14a4f52d0ce261b54d313ad3eee6cf46d1";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      deploy-rs,
      flake-parts,
      home-manager,
      home-manager-unstable,
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      self,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          config,
          system,
          inputs',
          pkgs,
          ...
        }:
        {
          # apply overlays to flake-parts: https://flake.parts/overlays#consuming-an-overlay
          _module.args.pkgs = import inputs.nixpkgs (
            { inherit system; } // (import ./nixpkgs.nix { inherit outputs; })
          );

          # custom packages
          packages = import ./pkgs { inherit inputs pkgs; };

          # devshells for flake development
          devShells =
            let
              shells = import ./shells.nix {
                inherit inputs' pkgs;
                treefmt = config.treefmt.build.wrapper;
              };
            in
            shells
            // {
              _aggregate = pkgs.releaseTools.aggregate {
                constituents = lib.attrValues shells;
                name = "devshell-${system}";
              };
            };

          treefmt = import ./treefmt.nix;
        };

      flake =
        let
          sources = import ./modules/sources.nix inputs;
        in
        rec {
          globals = import ./globals.nix { inherit lib; };

          # custom packages and modifications, exported as overlays
          overlays = import ./overlays { inherit inputs; };

          nixosConfigurations =
            {
              # Desktop
              iapetus = nixpkgs-unstable.lib.nixosSystem {
                specialArgs = {
                  inherit self inputs outputs;
                };
                modules = [
                  sources
                  ./machines/iapetus/configuration.nix
                ];
              };

              # GE73VR Laptop
              callisto = lib.nixosSystem {
                specialArgs = {
                  inherit self inputs outputs;
                };
                modules = [
                  sources
                  ./machines/callisto/configuration.nix
                ];
              };

              # Server
              sagittarius = lib.nixosSystem {
                specialArgs = {
                  inherit self inputs outputs;
                };
                modules = [
                  sources
                  ./machines/sagittarius/configuration.nix
                ];
              };

              # Voron 2.4r2 Klipper machine
              voron = lib.nixosSystem {
                specialArgs = {
                  inherit self inputs outputs;
                };
                modules = [
                  sources
                  ./machines/voron/configuration.nix
                ];
                system = "aarch64-linux";
              };
            }
            // (import ./machines/print-farm {
              inherit self inputs outputs;
              sources = sources;
            });

          darwinConfigurations = {
            "enceladus" = nix-darwin.lib.darwinSystem {
              specialArgs = {
                inherit self inputs outputs;
              };
              modules = [
                sources
                ./machines/enceladus/configuration.nix
              ];
            };
          };

          homeConfigurations = {
            "nregner@iapetus" = home-manager-unstable.lib.homeManagerConfiguration {
              pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
              extraSpecialArgs = {
                inherit self inputs outputs;
              };
              modules = [
                sources
                ./machines/iapetus/home.nix
              ];
            };
            "nregner@callisto" = home-manager-unstable.lib.homeManagerConfiguration {
              pkgs = nixpkgs-unstable.legacyPackages.x86_64-linux;
              extraSpecialArgs = {
                inherit self inputs outputs;
              };
              modules = [
                sources
                ./machines/callisto/home.nix
              ];
            };
            "nregner@enceladus" = home-manager-unstable.lib.homeManagerConfiguration {
              pkgs = nixpkgs-unstable.legacyPackages.aarch64-darwin;
              extraSpecialArgs = {
                inherit self inputs outputs;
              };
              modules = [
                sources
                ./machines/enceladus/home.nix
              ];
            };
          };

          images = lib.mapAttrs (
            name: nixosConfiguration:
            let
              inherit (nixosConfiguration) config pkgs;
              inherit (config.nixpkgs.hostPlatform) system;
            in
            {
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
                        cp ${pkgs.writeShellScript "install" ''
                          sudo nixos-install --root /mnt --flake ${self.outPath}#${name}
                        ''} $out/bin/nixos-install-flake
                      '')
                    ];
                    isoImage.squashfsCompression = "zstd -Xcompression-level 1";
                  }
                ];
                format = "install-iso";
              };
            }
          ) nixosConfigurations;

          deploy.nodes =
            let
              homeProfiles = (
                activate: hostName:
                let
                  homeConfiguration = homeConfigurations."nregner@${hostName}" or null;
                in
                if homeConfiguration != null then
                  {
                    home = {
                      user = "nregner";
                      path = activate homeConfiguration;
                    };
                  }
                else
                  { }
              );
              systemProfiles =
                type:
                lib.mapAttrs (
                  name:
                  { config, ... }@systemConfiguration:
                  {
                    hostname = config.networking.hostName;
                    profiles =
                      let
                        activate = deploy-rs.lib.${config.nixpkgs.hostPlatform.system}.activate;
                      in
                      {
                        system = {
                          user = "root";
                          path = activate.${type} systemConfiguration;
                        };
                      }
                      // (homeProfiles activate.home-manager config.networking.hostName);
                  }
                );
            in
            systemProfiles "nixos" nixosConfigurations // systemProfiles "darwin" darwinConfigurations;

          hydraJobs = {
            # TODO: is this even needed or are inputs already cached?
            flakeInputs =
              let
                pkgs = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux;
                recurse = (
                  parent: inputs:
                  (lib.mapAttrsToList (name: input: {
                    name = "${parent}${name}";
                    path = input.outPath;
                  }) inputs)
                  ++ (builtins.concatLists (
                    builtins.attrValues (
                      builtins.mapAttrs (name: input: recurse "${parent}${name}." input.inputs or { }) inputs
                    )
                  ))
                );
              in
              pkgs.linkFarm "flake-inputs" (lib.unique (recurse "" inputs));

            deploy = lib.mapAttrs (
              name: { profiles, ... }: builtins.mapAttrs (_: { path, ... }: path) profiles
            ) deploy.nodes;

            devShells = lib.mapAttrs (system: { _aggregate, ... }: _aggregate) (
              lib.getAttrs [
                "x86_64-linux"
                "aarch64-darwin"
              ] outputs.devShells
            );
          };
        };
    };
}
