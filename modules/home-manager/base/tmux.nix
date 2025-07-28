{ config, pkgs, ... }:
{
  xdg.configFile."tmux/user.conf".source = config.lib.file.mkFlakeSymlink ./tmux.conf;

  programs.tmux = {
    enable = true;
    extraConfig = ''
      unbind r
      bind-key r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "tmux.conf reloaded"

      set-option -g default-command "$SHELL"
      source-file ${config.xdg.configHome}/tmux/user.conf
    '';
    plugins = with pkgs.unstable.tmuxPlugins; [ yank ];
  };

  programs.zsh.initContent = builtins.readFile ./tmux.sh;

  home.packages = with pkgs.unstable; [ tmux-sessionizer ];
}
