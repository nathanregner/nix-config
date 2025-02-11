{
  self,
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.programs.nregner.home-manager = {
    enable = lib.mkEnableOption "Enable minimal home-manager profile for server usage";
  };

  config = lib.mkIf config.programs.nregner.home-manager.enable {
    programs.zsh.enable = true;
    users.users.nregner.shell = pkgs.zsh;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit
          self
          inputs
          outputs
          ;
      };
      users.nregner = {
        imports = [ ../../../home-manager/server ];

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        home.stateVersion = "23.05";
      };
    };
  };
}
