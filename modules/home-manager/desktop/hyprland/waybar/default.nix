{ inputs, config, pkgs, ... }: {
  xdg.configFile = {
    "waybar/config".source = config.lib.file.mkFlakeSymlink ./config.json;
    "waybar/style.css".source = config.lib.file.mkFlakeSymlink ./style.css;
    "waybar/mocha.css".source = "${inputs.catppuccin-waybar}/themes/mocha.css";
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = inputs.nixpkgs-wayland.packages.${pkgs.system}.waybar;
  };
}
