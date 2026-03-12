{
  cargo,
  clippy,
  mkShell,
  rust-analyzer,
  rustfmt,
}:
{
  pkg,
  rustPlatform,
  packages ? [ ],
  ...
}@args:
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
      ]
      ++ packages;
  }
  // (removeAttrs args [
    "pkg"
    "rustPlatform"
    "packages"
  ])
)
