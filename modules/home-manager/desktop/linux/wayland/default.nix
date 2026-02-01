{ inputs, pkgs, ... }:
let
  import-env = pkgs.writeShellScriptBin "import-env" (builtins.readFile ./import-env.sh);
in
{
  imports = [
    # TODO: opt-in to individual components options
    ../.
    ./bar/waybar
    ./clipboard.nix
    ./launcher/tofi.nix
    ./lock/hyprlock.nix
    ./notification/mako.nix
  ]
  ++ (with inputs.self.modules.homeManager; [
    niri
  ]);

  home.packages = [
    import-env
  ]
  ++ (with pkgs.unstable; [
    evince # documents
    loupe # images
    nautilus # files
  ]);

  # auto mount disks
  services.udiskie.enable = true;
}
