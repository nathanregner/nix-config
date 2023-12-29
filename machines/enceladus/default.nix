{
  system = "aarch64-darwin";

  darwinConfigurations."Nathans-MacBook-Pro".modules =
    [ ../../modules/darwin/default.nix ./configuration.nix ];

  homeConfigurations."nregner".modules =
    [ ../../modules/home-manager/desktop ./home.nix ];
}
