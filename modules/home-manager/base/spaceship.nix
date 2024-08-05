{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.zsh.prompt.spaceship;
in
{
  options = {
    programs.zsh.prompt.spaceship = {
      enable = lib.mkEnableOption "Enable the spaceship zsh prompt";

      configFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the spaceship configuration file.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.initExtra = ''
      source ${pkgs.unstable.spaceship-prompt}/lib/spaceship-prompt/spaceship.zsh
    '';

    xdg.configFile."spaceship.zsh".source = cfg.configFile;
  };
}
