{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.kanata-switcher.nixosModules.default
  ];

  services.kanata = {
    enable = true;
    package = pkgs.unstable.kanata;
    keyboards.main = {
      port = 10000;
      extraDefCfg = ''
        process-unmapped-keys yes
      '';
      # https://github.com/jtroo/kanata/blob/main/docs/config.adoc#tap-hold
      config = /* scheme */ ''
        (defsrc
          caps
          mlft mrgt mmid)

        (deflayer browser)

        (defvirtualkeys
          vk_browser (layer-while-held browser))

        (defalias
          kp-n (switch
            ((input virtual vk_browser)) down break
            () n break)
          kp-p (switch
            ((input virtual vk_browser)) up break
            () p break))

        (deflayermap (default-layer)
          @kp-n @kp-p
          caps (tap-hold-press 0 250 esc lctl)
          mlft mlft
          mrgt mrgt
          mmid mmid)
      '';
    };
  };

  # https://github.com/7mind/kanata-switcher/tree/main#nixos-module-nixos
  services.kanata-switcher = {
    enable = true;
    kanataPort = config.services.kanata.keyboards.main.port;
    settings = [
      {
        class = "^firefox$";
        layer = "browser";
      }
    ];
  };
}
