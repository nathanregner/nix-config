{ pkgs, ... }:
{
  services.mainsail = {
    enable = true;
    package = pkgs.unstable.mainsail;
  };
  services.nginx = {
    clientMaxBodySize = "1G";
  };

  # systemd.services.ustreamer = {
  #   description = "Mainsail webcam stream";
  #   script = with pkgs; ''
  #     ${ustreamer}/bin/ustreamer --device /dev/video0 --host 0.0.0.0 --port 81
  #   '';
  #   serviceConfig = {
  #     Restart = "on-failure";
  #     RestartSec = "1s";
  #     RestartSteps = 10;
  #     RestartMaxDelaySec = "1m";
  #   };
  # };

  # # restart ustreamer when webcam is plugged in
  # services.udev.extraRules = ''
  #   ACTION=="add", ENV{SUBSYSTEM}=="video4linux", RUN+="${pkgs.systemd}/bin/systemctl restart ustreamer.service"
  # '';

  services.mediamtx = {
    enable = true;
    allowVideoAccess = true;
    # package = pkgs.mediamtx-v0_2;
    settings = {
      paths.cam = {
        # runOnInit = "ffmpeg -f v4l2 -i /dev/video0 -c:v libx264 -preset ultrafast -b:v 600k -f rtsp rtsp://localhost:$RTSP_PORT/$MTX_PATH";
        runOnInit = "bash -c 'GST_V4L2_USE_LIBV4L2=1 gst-launch-1.0 v4l2src device=/dev/video0 ! x264enc ! rtspclientsink location=rtsp://localhost:$RTSP_PORT/$MTX_PATH'";
        runOnInitRestart = true;
      };
      # https://github.com/bluenviron/mediamtx#webrtc-specific-features
      # webrtcAdditionalHosts = [
      #   "voron"
      #   "voron.nregner.net"
      # ];
    };
  };

  systemd.services.mediamtx = {
    # environment = {
    #   GST_V4L2_USE_LIBV4L2 = "1";
    # };
    path = with pkgs.unstable; [
      bash
      gst_all_1.gstreamer
      gst_all_1.gst-rtsp-server
      gst_all_1.gst-plugins-base
      # Specialized plugins separated by quality
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      # Plugins to reuse ffmpeg to play almost every video format
      gst_all_1.gst-libav
      # Support the Video Audio (Hardware) Acceleration API
      gst_all_1.gst-vaapi
    ];
  };

  environment.systemPackages = with pkgs.unstable; [
    gst_all_1.gstreamer
    gst_all_1.gst-rtsp-server
    gst_all_1.gst-plugins-base
    # Specialized plugins separated by quality
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    # Plugins to reuse ffmpeg to play almost every video format
    gst_all_1.gst-libav
    # Support the Video Audio (Hardware) Acceleration API
    gst_all_1.gst-vaapi
  ];

  networking.firewall =
    let
      ports = [
        80
        8189
        8889
      ];
    in
    {
      allowedTCPPorts = ports;
      allowedUDPPorts = ports;
    };
}
