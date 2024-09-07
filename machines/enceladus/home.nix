{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home-manager/darwin
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/jetbrains
    inputs.mac-app-util.homeManagerModules.default
  ];

  programs.alacritty.settings = {
    font = {
      size = lib.mkForce 11;
    };
  };

  home = {
    username = "nregner";
    homeDirectory = "/Users/nregner";
    flakePath = "/Users/nregner/nix-config";
    # Use a case-sensitive file system for nix builds
    sessionVariables = {
      TMPDIR = "/Volumes/tmp";
    };
  };

  home.packages = with pkgs.unstable; [
    # apps
    rectangle

    # tools
    awscli2
    gh
    nushell
    sops

    # nix
    nix-output-monitor
    nixfmt-rfc-style
    nvfetcher
    # nix-du # nix-du -s=500MB | xdot -
    xdot
    nixos-rebuild
  ];

  programs.tmux-sessionizer = {
    # fix permission denied errors trying to read /Volumes/dev
    excluded_dirs = [
      ".DocumentRevisions-V100"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".fseventsd"
      ".pnpm-store"
    ];
  };

  # # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
  # # https://github.com/rui314/mold?tab=readme-ov-file#how-to-use
  # # https://discourse.nixos.org/t/create-nix-develop-shell-for-rust-with-mold/35894/6
  # home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" ''
  #   [target.aarch64-apple-darwin]
  #   linker = "${(lib.getExe' ((pkgs.unstable.stdenvAdapters.useMoldLinker pkgs.unstable.clangStdenv).cc) "clang")}"
  #   rustflags = ["-C", "link-arg=-undefined", "-C", "link-arg=dynamic_lookup", "-C", "target-cpu=native"]
  # '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
