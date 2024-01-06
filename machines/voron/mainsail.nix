{ pkgs, ... }: {
  services.mainsail = {
    package = pkgs.mainsail-develop;
    enable = true;
  };
  services.nginx = { clientMaxBodySize = "1G"; };

  systemd.services.ustreamer = {
    description = "Mainsail webcam stream";
    script = with pkgs; ''
      ${ustreamer}/bin/ustreamer --device /dev/video0 --host 0.0.0.0 --port 81
    '';
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "1s";
      RestartSteps = 10;
      RestartMaxDelaySec = "1m";
    };
  };

  # restart ustreamer when webcam is plugged in
  services.udev.extraRules = ''
    ACTION=="add", ENV{SUBSYSTEM}=="video4linux", RUN+="${pkgs.systemd}/bin/systemctl restart ustreamer.service"
  '';

  networking.firewall = let ports = [ 80 81 ];
  in {
    allowedTCPPorts = ports;
    allowedUDPPorts = ports;
  };
}
