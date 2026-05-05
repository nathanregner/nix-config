{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pup";
  version = "0.56.3";

  src = fetchFromGitHub {
    owner = "datadog-labs";
    repo = "pup";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LAiMJHOfIvydzZPKo3u8Wd6buXapMZVR2av+pCCJCEc=";
  };

  cargoHash = "sha256-APIA2j0B40R183f5cGCpOopFOhC3t5B5JJ6EF19z/bk=";

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
