{
  config,
  pkgs,
  lib,
  ...
}:
let
  toml = pkgs.formats.toml { };
  direnvConfig = pkgs.linkFarm "direnv-sandbox-config" [
    {
      name = "direnv/direnv.toml";
      path = toml.generate "direnv.toml" { whitelist.prefix = [ "/" ]; };
    }
  ];

  direnvWrapper =
    pkgs.runCommand "direnv-sandbox-wrapper"
      {
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeBinaryWrapper ${lib.getExe pkgs.direnv} $out/bin/direnv \
          --set XDG_CONFIG_HOME "${direnvConfig}"
      '';
in
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

  # programs.claude-code.merged-hooks.PreToolUse = [
  #   { command = toString ./direnv-hook.nu; }
  # ];

  programs.claude-code.sandbox.allowedPackages = [ direnvWrapper ];

  xdg.configFile."direnv/lib/_layout.sh".source = config.lib.file.mkFlakeSymlink ./_layout.sh;
}
