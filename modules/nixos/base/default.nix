{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.catppuccin-nix.nixosModules.catppuccin
    inputs.nixos-generators.nixosModules.all-formats
    ./docker.nix
    ./keyd.nix
    ./networking.nix
    ./nix.nix
    ./services
    ./sops.nix
    ./tailscale.nix
    ./users.nix
  ];

  time.timeZone = "America/Boise";
  i18n.defaultLocale = "en_US.UTF-8";

  # theme
  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
    dates = "weekly";
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  boot.tmp.cleanOnBoot = true;

  # https://github.com/NixOS/nix/issues/7154
  # boot.tmp.useTmpfs = true;
  # nix.settings.store = "daemon";
  # systemd.services."nix-daemon".environment.TMPDIR = "/nix/tmp";
  # systemd.tmpfiles.rules = [
  #   "d /nix/tmp 770 root nixbld"
  # ];

  # basic system utilities
  environment.systemPackages = with pkgs.unstable; [
    git # needed by flakes

    # text manipulation
    gawk
    gnused
    ripgrep
    vim

    # filesystem
    dua
    fd
    file
    rsync
    tree
    which

    # archive formats
    gnutar
    unzip
    xz
    zip
    zstd

    # system monitoring
    htop-vim
    iftop
    iotop
    lm_sensors # for `sensors` command
    nmon
    pik

    # networking
    curl
    dig
    ethtool
    iperf2
    iputils
    mtr
    nmap
    socat
    tcpdump
    wget

    # debugging
    strace
    ltrace
    lsof
  ];
}
