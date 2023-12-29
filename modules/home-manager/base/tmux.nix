{ config, pkgs, ... }: {
  xdg.configFile."tmux/user.conf".source =
    config.lib.file.mkFlakeSymlink ./tmux.conf;

  programs.tmux = {
    enable = true;
    extraConfig = ''
      unbind r
      bind-key r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "tmux.conf reloaded"

      source-file ${config.xdg.configHome}/tmux/user.conf
    '';
    plugins = with pkgs.unstable.tmuxPlugins; [ resurrect yank ];
  };

  home.packages = with pkgs.unstable; [ tmux-sessionizer ];
}
