{
  options,
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
      configDir = mkOption { type = types.path; };
      features = mkOption { type = types.attrsOf types.bool; };
      packages = mkOption {
        type = types.submodule {
          options = {
            kernel = mkOption {
              type = types.package;
              default = pkgs.linuxPackages.kernel;
            };
            linux = mkOption {
              default = pkgs.linuxKernel;
            };
          };
        };
        default = { };
      };
      inherit (options.boot) kernelPatches;
      _devShell = mkReadOnlyOption (
        pkgs.mkShell {
          env = {
            KERNEL_SRC = "${pkgs.srcOnly cfg.packages.kernel}";
            PKG_CONFIG_PATH = lib.concatStringsSep ":" [
              "${pkgs.ncurses.dev}/lib/pkgconfig"
            ];
          };
          shellHook = ''
            . ${./shell-hook.sh} ${lib.head (builtins.match "/nix/store/[^/]+/(.*)" (toString cfg.configDir))}
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
    boot.kernelPackages = cfg.packages.linux.packagesFor (
      (cfg.packages.linux.manualConfig rec {
        inherit (cfg.packages.kernel) src version;
        config = builtins.fromJSON (builtins.readFile "${cfg.configDir}/.config.json");
        configfile = "${cfg.configDir}/.config";
        modDirVersion = lib.versions.pad 3 version;
        inherit (cfg) kernelPatches;
      }).overrideAttrs
        (old: {
          passthru = old.passthru // {
            inherit (cfg) features;
          };
        })
    );
  };
}
