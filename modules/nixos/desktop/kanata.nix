{ pkgs, ... }:
{
  services.kanata = {
    enable = true;
    package = pkgs.unstable.kanata;
    keyboards.main = {
      extraDefCfg = ''
        process-unmapped-keys yes
      '';
      # https://github.com/jtroo/kanata/blob/main/docs/config.adoc#tap-hold
      config =
        # scheme
        ''
          (defsrc
            caps
            mlft mrgt mmid)

          (deflayermap (default-layer)
            caps (tap-hold-press 0 250 esc lctl)
            mlft mlft
            mrgt mrgt
            mmid mmid)
        '';
    };
  };
}
