{
  services.keyd = {
    enable = true;
    # https://github.com/rvaiya/keyd
    keyboards.default.settings = {
      global = {
        overload_tap_timeout = 250;
      };
      main = {
        capslock = "overload(control, esc)"; # remap to escape when pressed and control when held
        rightcontrol = "capslock";
      };
    };
  };
}
