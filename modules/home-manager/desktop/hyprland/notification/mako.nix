{ pkgs, ... }:
{
  catppuccin.mako.enable = true;

  home.packages = with pkgs; [ libnotify ];

  services.mako = {
    enable = true;
    settings = {
      defaultTimeout = 10000;
      font = "JetBrainsMono Nerd Font";
      groupBy = "summary";
      margin = "20,20,10,0";
      padding = "10";
    };
  };
}
