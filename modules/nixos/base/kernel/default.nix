{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.local.kernel;
  inherit (lib) mkEnableOption mkOption types;
  mkReadOnlyOption =
    value:
    mkOption {
      readOnly = true;
      default = value;
    };
in
{
  options = {
    local.kernel = {
      enable = mkEnableOption "custom kernel";
      dir = mkOption { type = types.path; };
      features = mkOption { type = types.attrsOf types.bool; };
      pkgs = mkOption {
        type = types.submodule {
          options = {
            kernel = mkOption { type = types.package; };
            linux = mkOption { };
          };
        };
        default = {
          kernel = pkgs.linuxPackages.kernel;
          linux = pkgs.linuxKernel;
        };
      };
      _devShell = mkReadOnlyOption (
        pkgs.mkShell {
          env = {
            KERNEL_SRC = "${pkgs.srcOnly cfg.pkgs.kernel}";
            PKG_CONFIG_PATH = lib.concatStringsSep ":" [
              "${pkgs.ncurses.dev}/lib/pkgconfig"
            ];
          };
          shellHook = ''
            . ${./shell-hook.sh} ${lib.head (builtins.match "/nix/store/[^/]+/(.*)" (toString cfg.dir))}
          '';
          packages = with pkgs; [
            (pkgs.writers.writeNuBin "parse-config" ./parse-config.nu)
            bc
            bison
            flex
            pkg-config
          ];
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = cfg.pkgs.linux.packagesFor (
      (cfg.pkgs.linux.manualConfig rec {
        inherit (cfg.pkgs.kernel) src version;
        config = builtins.fromJSON (builtins.readFile "${cfg.dir}/.config.json");
        configfile = "${cfg.dir}/.config";
        modDirVersion = lib.versions.pad 3 version;
      }).overrideAttrs
        (old: {
          passthru = old.passthru // {
            inherit (cfg) features;
          };
        })
    );
  };
}
