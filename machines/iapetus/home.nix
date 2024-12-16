{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/gnome
    ../../modules/home-manager/desktop/hyprland
  ];

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/iapetus";
  };

  hyprland = {
    enable = true;
    monitors = [
      {
        name = "desc:Ancor Communications Inc VG248 J6LMQS041978";
        resolution = "1920x1080@144";
        position = "0x0";
        workspaces = [
          1
          2
          3
          4
          5
        ];
      }
      {
        name = "desc:Ancor Communications Inc VG248 JBLMQS148602";
        resolution = "1920x1080@144";
        position = "1920x0";
        workspaces = [
          6
          7
          8
          9
          0
        ];
      }
    ];
    wallpaper = ../../assets/planet-rise.png;
  };

  # Prefer primary GPU if not captured by VFIO
  wayland.windowManager.hyprland.extraConfig = ''
    env = WLR_DRM_DEVICES,$HOME/.config/hypr/cards/rtx-2070:$HOME/.config/hypr/cards/gtx-1060
  '';
  # Link GPU devices to get rid of ":" in file names
  # https://wiki.hyprland.org/Configuring/Multi-GPU/
  systemd.user.tmpfiles.rules = [
    "L+ /home/nregner/.config/hypr/cards/gtx-1060 - - - - /dev/dri/by-path/pci-0000:24:00.0-card"
    "L+ /home/nregner/.config/hypr/cards/rtx-2070 - - - - /dev/dri/by-path/pci-0000:2d:00.0-card"
  ];

  programs.zsh.initExtra = ''
    export PATH="$PATH:$HOME/.cargo/bin"
    export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
  '';

  home.packages = with pkgs.unstable; [
    # apps
    discord
    evince
    firefox
    insync
    jetbrains-toolbox
    openrgb

    awscli2
    babashka
    dust
    gh
    jq
    nushell
    pv
    rclone
    restic
    screen
    xclip

    # k8s
    kubectl
    kubernetes-helm

    # 3d printer
    cura5
    orca-slicer
    super-slicer-beta

    # nix
    nix-output-monitor
    nixfmt-rfc-style
    nix-du # nix-du -s=500MB | xdot -
    xdot

    # rust
    cargo-autoinherit
    cargo-outdated

    # rc
    betaflight-configurator
  ];

  programs.nvfetcher.enable = true;

  xdg.desktopEntries.discord = {
    type = "Application";
    name = "Discord";
    comment = "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
    genericName = "Internet Messenger";
    # exec = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland";
    exec = "discord --disable-gpu";
    icon = "discord";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
  # https://github.com/rui314/mold?tab=readme-ov-file#how-to-use
  # https://discourse.nixos.org/t/create-nix-develop-shell-for-rust-with-mold/35894/6
  home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" ''
    [target.x86_64-unknown-linux-gnu]
    linker = "${(lib.getExe' ((pkgs.unstable.stdenvAdapters.useMoldLinker pkgs.unstable.clangStdenv).cc) "clang")}"
  '';

  programs.alacritty.settings = {
    font = {
      size = lib.mkForce 11;
    };
  };

  services.easyeffects.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
