{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pup";
  version = "0.47.0";

  src = fetchFromGitHub {
    owner = "datadog-labs";
    repo = "pup";
    tag = "v${finalAttrs.version}";
    hash = "sha256-C6g8eG9xzfLwKWxwW0DSww8bHDMKVB2cNIQI2uCPChs=";
  };

  cargoHash = "sha256-K/1RUkpBuXCDTEXHqTrDSYNGwSjgjffxBnJ/PeOFTFY=";

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
