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
            caps)

          (deflayermap (default-layer)
            caps (tap-hold-press 0 100 esc lctl))
        '';
    };
  };
}
