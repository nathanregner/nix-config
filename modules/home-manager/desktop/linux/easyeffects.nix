{
  services.easyeffects.enable = true;

  # Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
  dconf.settings = {
    "com/github/wwmm/easyeffects/streamoutputs" = {
      blocklist = [
        "WEBRTC VoiceEngine"
        "win10"
      ];
      output-device = "alsa_output.usb-SteelSeries_Arctis_Nova_7-00.analog-stereo";
      plugins = [
        "bass_enhancer#0"
      ];
    };

    "com/github/wwmm/easyeffects/streamoutputs/bassenhancer/0" = {
      amount = 6.0;
      bypass = false;
      input-gain = -8.0;
      listen = false;
      output-gain = 0.0;
    };
  };
}
