{ pkgs, lib, ... }:
{
  home.packages = with pkgs.unstable; [
    cargo-autoinherit
    cargo-outdated
  ];

  programs.zsh.initContent = ''
    export PATH="$PATH:$HOME/.cargo/bin"
  '';
}
# // lib.optionalAttrs pkgs.stdenv.isLinux {
#   # rustc -Z unstable-options --print target-spec-json | jq '.["llvm-target"]' -r
#   # https://github.com/rui314/mold?tab=readme-ov-file#how-to-use
#   # https://discourse.nixos.org/t/create-nix-develop-shell-for-rust-with-mold/35894/6
#   home.file.".cargo/config.toml".source = pkgs.writeText "config.toml" ''
#     [target.x86_64-unknown-linux-gnu]
#     linker = "${(lib.getExe' (pkgs.unstable.stdenvAdapters.useMoldLinker pkgs.unstable.clangStdenv).cc "clang")}"
#   '';
# }
