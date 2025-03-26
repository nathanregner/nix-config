{
  cargo,
  clippy,
  mkShellNoCC,
  rust-analyzer,
  rustfmt,
  ...
}:
{ pkg, rustPlatform, ... }@args:
mkShellNoCC (
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
