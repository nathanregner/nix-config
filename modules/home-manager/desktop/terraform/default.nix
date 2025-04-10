{
  home.file = {
    ".terraform.d/plugin-cache/.mkdir".text = "";
    ".terraformrc".text =
      # hcl
      ''
        plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"
        disable_checkpoint = true
      '';
  };
}
