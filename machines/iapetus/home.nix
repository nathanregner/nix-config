{ lib, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/gnome
    ../../modules/home-manager/desktop/hyprland
    ../../terraform/tailscale
  ];

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/iapetus";
  };

  home.packages = with pkgs.unstable; [
    # apps
    discord
    firefox
    google-drive-ocamlfuse
    jetbrains-toolbox
    openrgb
    pkgs.insync

    awscli2
    gh
    jq
    nushellFull
    pv
    rclone
    restic
    screen
    xclip

    # k8s
    kubectl
    kubernetes-helm

    # 3d printer
    super-slicer-latest

    # nix
    comma # auto-run from nix-index: https://github.com/nix-community/comma
    nix-output-monitor
    nix-prefetch
    nixfmt
    nix-du # nix-du -s=500MB | xdot -
    pkgs.xdot-darwin

    # rc
    betaflight-configurator
  ];

  # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
  home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" ''
    [target.x86_64-unknown-linux-gnu]
    linker = "${pkgs.clang}/bin/clang"
    rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.unstable.mold}/bin/mold", "-C", "target-cpu=native"]
  '';

  programs.alacritty.settings = { font = { size = lib.mkForce 11; }; };

  services.easyeffects.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
