{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "genai-toolbox";
  version = "0.31.0";

  src = fetchFromGitHub {
    owner = "googleapis";
    repo = "genai-toolbox";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hD5HumHx+juSkJCA6pRYzForAqZKvNRFpnhmeylgHZ4=";
  };

  vendorHash = "sha256-ByCaEsv+SdzbqAdwWmzfUDKwJ76iyojG0qlp3SWo01M=";

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${finalAttrs.version}"
  ];

  # Tests require network access and database connections
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    changelog = "https://github.com/googleapis/genai-toolbox/releases/tag/v${finalAttrs.version}";
    description = "MCP Toolbox for Databases - an open source MCP server for databases";
    homepage = "https://github.com/googleapis/genai-toolbox";
    license = lib.licenses.asl20;
    mainProgram = "genai-toolbox";
    maintainers = [ ];
  };
})
