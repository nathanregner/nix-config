{
  lib,
  fetchFromGitHub,
  fetchYarnDeps,
  graphql-language-service-cli,
  makeWrapper,
  nix-update-script,
  nodejs,
  stdenv,
  testers,
  yarnBuildHook,
  yarnConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "graphql-language-service-cli";
  version = "graphiql@3.8.3";

  src = fetchFromGitHub {
    owner = "graphql";
    repo = "graphiql";
    tag = "graphql-language-service-cli@${finalAttrs.version}";
    hash = "sha256-2TiJsEc1kzUJiLnqtUhmR/ouqx2OOdvHPXU4z8vn2Es=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-ALE7CQdrfhjdmHJ6GNgcXNaNxu85m/4eivfkZVyw/cI=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}

    pushd packages/graphql-language-service-cli

    # even with dev dependencies stripped, node_modules is over 1GB
    # just bundle what we need
    cp ${./esbuild.js} esbuild.js
    node esbuild.js

    # copy package.json for --version command
    mv {out/graphql.js,package.json} $out/lib

    makeWrapper ${nodejs}/bin/node $out/bin/graphql-lsp \
      --add-flags $out/lib/graphql.js \

    popd

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "graphql-language-service-cli@(.*)"
      ];
    };
    tests.version = testers.testVersion {
      package = graphql-language-service-cli;
    };
  };

  meta = {
    description = "The official, runtime independent Language Service for GraphQL";
    homepage = "https://github.com/graphql/graphiql";
    changelog = "https://github.com/graphql/graphiql/blob/${finalAttrs.src.tag}/packages/graphql-language-service-cli/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ nathanregner ];
    mainProgram = "graphql-ls";
  };
})
