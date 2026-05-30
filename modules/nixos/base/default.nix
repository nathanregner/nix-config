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
    ./networking.nix
    ./nix.nix
    ./services
    ./tailscale.nix
    ./users.nix
  ]
  ++ (with inputs.self.modules.nixos; [
    base
  ]);

  time.timeZone = "America/Boise";
  i18n.defaultLocale = "en_US.UTF-8";

  # theme
  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  boot.kernel.sysctl = {
    "kernel.sysrq" = "1"; # https://github.com/NixOS/nixpkgs/issues/83694
    "vm.swappiness" = 10;
  };

  boot.tmp.cleanOnBoot = true;

  programs.vim = {
    defaultEditor = true;
    enable = true;
  };

  programs.nano.enable = false;

  # basic system utilities
  environment.systemPackages = with pkgs; [
    # text manipulation
    gawk
    gnused
    ripgrep

    # filesystem
    dua
    fd
    file
    pv
    rsync
    tree
    which

    # archive formats
    ouch

    # system monitoring
    htop-vim
    iftop
    iotop
    lm_sensors # for `sensors` command
    nmon

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
