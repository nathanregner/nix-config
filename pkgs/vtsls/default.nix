{
  makeWrapper,
  node2nixPkgs,
}:
node2nixPkgs."@vtsls/language-server".overrideAttrs {
  nativeBuildInputs = [ makeWrapper ];

  # default "watchFile" -> "useFsEventsOnParentDirectory"
  # https://github.com/microsoft/TypeScript/blob/0f4737e0d55363ac40198b33a80fff0d01c1d8cf/src/compiler/sys.ts#L1517
  # https://github.com/microsoft/vscode/issues/13953
  postInstall = ''
    wrapProgram "$out/bin/vtsls" \
      --set TSC_NONPOLLING_WATCHER true
  '';
}
