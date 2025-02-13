{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.clojure;
in
{
  options = {
    programs.neovim.modules.clojure.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.file.".lein/profiles.clj".source = ./profiles.clj;

    home.packages = [ pkgs.unstable.babashka ];

    programs.neovim = {
      extraPackages = with pkgs.unstable; [
        clojure-lsp
        joker # formatter
      ];
    };
  };
}
