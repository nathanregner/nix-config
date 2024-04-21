{ lib, pkgs, ... }: {
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
        name = "DP-1";
        resolution = "1920x1080@144";
        position = "0x0";
      }
      {
        name = "DP-2";
        resolution = "1920x1080@144";
        position = "1920x0";
      }
    ];
    wallpaper = ../../assets/planet-rise.png;
  };

  programs.zsh.initExtra = ''
    export PATH="$PATH:$HOME/.cargo/bin"
    export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
  '';

  home.packages = with pkgs.unstable; [
    # apps
    discord
    evince
    firefox
    jetbrains-toolbox
    openrgb
    pkgs.insync

    awscli2
    babashka
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
    cachix
    nix-output-monitor
    nixfmt
    nix-du # nix-du -s=500MB | xdot -
    nvfetcher
    hydra-cli
    xdot

    # rc
    betaflight-configurator
  ];

  xdg.desktopEntries.discord = {
    type = "Application";
    name = "Discord";
    comment =
      "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
    genericName = "Internet Messenger";
    # exec = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland";
    exec = "discord --disable-gpu";
    icon = "discord";
    categories = [ "Network" "InstantMessaging" ];
  };

  # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
  # https://github.com/rui314/mold?tab=readme-ov-file#how-to-use
  # https://discourse.nixos.org/t/create-nix-develop-shell-for-rust-with-mold/35894/6
  home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" ''
    [target.x86_64-unknown-linux-gnu]
    linker = "${
      (lib.getExe' ((pkgs.unstable.stdenvAdapters.useMoldLinker
        pkgs.unstable.clangStdenv).cc) "clang")
    }"
  '';

  programs.alacritty.settings = { font = { size = lib.mkForce 11; }; };

  services.easyeffects.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
