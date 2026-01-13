prev: pkg:
pkg.override {
  buildNpmPackage = prev.buildNpmPackage.override { nodejs = prev.nodejs_20; };
}
