{ config, ... }:
{
  xdg.cacheFile."terraform/plugins/.mkdir".text = "";

  home.file = {
    ".terraformrc".text =
      # hcl
      ''
        plugin_cache_dir = "${config.xdg.cacheHome}/terraform/plugins"
        disable_checkpoint = true
      '';
  };
}
