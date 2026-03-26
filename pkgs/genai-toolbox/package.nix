{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "genai-toolbox";
  version = "0.30.0";

  src = fetchFromGitHub {
    owner = "googleapis";
    repo = "genai-toolbox";
    tag = "v${finalAttrs.version}";
    hash = "sha256-J3o4pAfZ6YARWzJzJocN/9BMEBCW9jfaEVzSwHWfT3s=";
  };

  vendorHash = "sha256-vQklQYnA2tNFwXaU91wafbES/J8SAOn9P2ZN6No1oi0=";

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
