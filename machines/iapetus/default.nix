{
  system = "x86_64-linux";

  nixosConfigurations.iapetus.modules =
    [ ../../modules/nixos/default.nix ./configuration.nix ];

  homeConfigurations."nregner@iapetus".modules =
    [ ../../modules/home-manager/desktop ./home.nix ];
}
