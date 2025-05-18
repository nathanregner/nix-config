{
  cargo,
  clippy,
  mkShell,
  rust-analyzer,
  rustfmt,
}:
{ pkg, rustPlatform, ... }@args:
mkShell (
  {
    RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
    packages =
      pkg.nativeBuildInputs
      ++ pkg.buildInputs
      ++ [
        cargo
        clippy
        rust-analyzer
        rustfmt
      ];
  }
  // (builtins.removeAttrs args [
    "pkg"
    "rustPlatform"
  ])
)
