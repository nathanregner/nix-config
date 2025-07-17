{ pkgs, ... }:
let
  import-env = pkgs.writeShellScriptBin "import-env" (builtins.readFile ./import-env.sh);
in
{
  home.packages =
    [
      import-env
    ]
    ++ (with pkgs.unstable; [
      nautilus

      wl-clipboard

      grim
      slurp
    ]);

  # auto mount disks
  services.udiskie.enable = true;
}
