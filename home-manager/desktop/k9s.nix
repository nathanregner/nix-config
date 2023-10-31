{ inputs, config, ... }: {
  programs.k9s = {
    enable = true;
    skin =
      config.lib.formats.fromYAML "${inputs.catppuccin-k9s}/dist/mocha.yml";
  };
}
