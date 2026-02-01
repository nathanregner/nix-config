{
  flake.modules.homeManager.swww =
    { config, lib, ... }:
    {
      services.swww.enable = true;
      systemd.user.services.swww.Service.ExecStartPost = ''
        ${lib.getExe' config.services.swww.package "swww"} img ${../../../assets/planet-rise.png}
      '';
    };
}
