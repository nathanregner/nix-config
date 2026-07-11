{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pup";
  version = "1.6.3";

  src = fetchFromGitHub {
    owner = "datadog-labs";
    repo = "pup";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hhbcGCLBVH4aF0fAWDs7jI+ymameoKowbKaN4MSyoN4=";
  };

  cargoHash = "sha256-c7XUScom7kuhF487JNyY7QaZjHtRGBswzFToT/g/RVg=";

  # Tests require network access
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    changelog = "https://github.com/datadog-labs/pup/releases/tag/v${finalAttrs.version}";
    description = "CLI companion for AI agents with 200+ commands across 33+ Datadog products";
    homepage = "https://github.com/datadog-labs/pup";
    license = lib.licenses.asl20;
    mainProgram = "pup";
    maintainers = [ ];
  };
})
