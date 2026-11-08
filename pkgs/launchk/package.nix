{
  lib,
  fetchFromGitHub,
  llvmPackages,
  nix-update-script,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "launchk";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "intellekthq";
    repo = "launchk";
    tag = "launchk-${finalAttrs.version}";
    hash = "sha256-j9ZU3owYtbKBG4rxZG7GyWymYsFSGR9OJSV+21KBq/A=";
  };

  env.LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";

  cargoHash = "sha256-k/n22Bfg857bWFl8sVhZI3YI2i9JuWmT28zN86W/ing=";

  # git_version! shells out to git, which doesn't exist in the source tarball
  postPatch = ''
    substituteInPlace launchk/src/main.rs \
      --replace-fail 'git_version!()' '"${finalAttrs.version}"'
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "launchk-(.*)"
    ];
  };

  meta = {
    description = "Rust/Cursive TUI for observing launchd agents and daemons";
    homepage = "https://github.com/intellekthq/launchk";
    license = lib.licenses.mit;
    mainProgram = "launchk";
    platforms = lib.platforms.darwin;
  };
})
