{
  lib,
  python3,
  nix-update-script,
  fetchFromGitHub,
  libiconv,
  rustPlatform,
  stdenv,
  unstableGitUpdater,
}:
python3.pkgs.buildPythonPackage rec {
  pname = "preprocess_cancellation";
  version = "0.3.a2";
  format = "pyproject";
  disabled = python3.pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "nathanregner";
    repo = "preprocess_cancellation";
    rev = "7d16ded500424d8a25d504875a9ddf330d4459ff";
    hash = "sha256-2OC/wZiLSSBh99YOEgh0qQZ7nY3eyGCAAe8fPUWghws=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "./${src}/Cargo.lock";
  };

  nativeBuildInputs = with rustPlatform; [
    cargoCheckHook
    cargoSetupHook
    maturinBuildHook
  ];

  buildInputs = lib.optional stdenv.isDarwin libiconv;

  pythonImportsCheck = [ "preprocess_cancellation" ];

  nativeCheckInputs = [ python3.pkgs.pytestCheckHook ];

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version=branch=main" ];
    };
    # updateScript = unstableGitUpdater { };
  };

  meta = {

  };
}
