{ pkgs, lib, ... }:
{
  services.keyd = {
    enable = true;
    # https://github.com/rvaiya/keyd
    keyboards.default.settings = {
      global = {
        overload_tap_timeout = 500;
      };
      main = {
        capslock = "overload(caps_ctrl, esc)"; # remap to escape when pressed and control when held
      };
      caps_ctrl = lib.listToAttrs (map (key: lib.nameValuePair key "C-${key}") (import ./keys.nix)) // {
        n = "down";
        p = "up";
      };
    };
  };

  users.groups.keyd = { };

  # TOOD
  # systemd.services.keyd.restartTriggers = [ ];

  environment.systemPackages = [
    pkgs.keyd
  ];
}
