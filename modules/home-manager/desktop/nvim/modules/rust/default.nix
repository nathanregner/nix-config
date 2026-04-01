{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.rust;
in
{
  options.programs.neovim.modules.rust = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      (with pkgs.unstable; [
        cargo-autoinherit
        cargo-flamegraph
        cargo-generate
        cargo-nextest
        cargo-outdated
        cargo-udeps
      ])
      ++ [
        # https://github.com/rust-lang/cargo/issues/2904?timeline_page=1
        (pkgs.writeShellScriptBin "cargo-why-rebuild" /* bash */ ''
          CARGO_LOG=cargo::core::compiler::fingerprint=info cargo "$@" 2>&1 | grep -E "dirty|stale|rerun"
        '')
      ];

    # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
    # https://github.com/wild-linker/wild
    # readelf --string-dump .comment target/release/...
    home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" (
      lib.optionalString pkgs.stdenv.isLinux ''
        [target.x86_64-unknown-linux-gnu]
        linker = "${(lib.getExe' (pkgs.unstable.stdenvAdapters.useWildLinker pkgs.unstable.clangStdenv).cc "clang")}"
        rustflags = ["-Clink-arg=-fuse-ld=wild"]
      ''
    );

    programs.zsh.initContent = ''
      export PATH="$PATH:$HOME/.cargo/bin"
    '';

    programs.zsh.shellAliases = {
      cargo = "alias cargo='cargo --target-dir /tmp/cargo/build/$(dirname $(cargo locate-project --message-format plain))'";
    };
  };
}
