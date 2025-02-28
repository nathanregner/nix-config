{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  nodejs,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "prettierd";
  version = "0.26.1";

  src = fetchFromGitHub {
    owner = "fsouza";
    repo = "prettierd";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8IlPC4KCFKJAbCVPl+vK9WustevKHOLbh41F6vMwHX4=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-M7mLkDHJa4iz6u3LSIIq3xCbYbiR0pPAkOK1MjJKstI=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    nodejs
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "prettierd";
    description = "Prettier, as a daemon, for improved formatting speed";
    homepage = "https://github.com/fsouza/prettierd";
    license = lib.licenses.isc;
    changelog = "https://github.com/fsouza/prettierd/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    platforms = with lib.platforms; linux ++ darwin;
    maintainers = with lib.maintainers; [
      NotAShelf
      n3oney
    ];
  };
})
