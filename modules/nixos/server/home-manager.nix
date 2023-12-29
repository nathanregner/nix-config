{ inputs, outputs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  programs.zsh.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nregner = {
      imports = [ ../../home-manager/base ];
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      home.stateVersion = "23.05";
    };
    extraSpecialArgs = { inherit inputs outputs; };
  };
}
