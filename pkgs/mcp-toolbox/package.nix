{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "mcp-toolbox";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "googleapis";
    repo = "mcp-toolbox";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bGtRRMFKFi2SQIHCAHcbV1ljRupBfrnNodrekTQ44tE=";
  };

  vendorHash = "sha256-tk46JLmXiVzkD0yovQm8juXpEui0HT9O6mADIBQQE7U=";

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
    changelog = "https://github.com/googleapis/mcp-toolbox/releases/tag/v${finalAttrs.version}";
    description = "MCP Toolbox for Databases - an open source MCP server for databases";
    homepage = "https://github.com/googleapis/mcp-toolbox";
    license = lib.licenses.asl20;
    mainProgram = "mcp-toolbox";
    maintainers = [ ];
  };
})
