{ pkgs, ... }: {
  home.packages = with pkgs; [ libnotify ];

  services.mako = {
    enable = true;
    catppuccin.enable = true;

    font = "JetBrainsMono Nerd Font";

    margin = "20,20,10,0";
    padding = "10";
    defaultTimeout = 10000;
    groupBy = "summary";
  };
}
