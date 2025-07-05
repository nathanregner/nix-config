{ pkgs, ... }:
{
  services.keyd = {
    enable = true;
    # https://github.com/rvaiya/keyd
    keyboards.default.settings = {
      main = {
        capslock = "overload(control, esc)"; # remap to escape when pressed and control when held
        esc = "capslock";
      };
      control = {
        n = "down";
        p = "up";
      };
    };
  };

  # TOOD
  # systemd.services.keyd.restartTriggers = [ ];

  environment.systemPackages = [
    pkgs.keyd
  ];
}
