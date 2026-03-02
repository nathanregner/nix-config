{
  lib,
  fetchFromGitHub,
  nix-update-script,
  tmuxPlugins,
}:
tmuxPlugins.mkTmuxPlugin rec {
  pluginName = "tmux-claude-status";
  rtpFilePath = "${pluginName}.tmux";
  version = "0.unstable";
  src = fetchFromGitHub {
    owner = "samleeney";
    repo = pluginName;
    rev = "c6acf7a6ad285127a74d9dbbe7cebc7698feb41d";
    hash = "sha256-6kXXgxmphQ6Hs0PDZaX8Eusd+bxIayAm6UwyFDyGIdc=";
  };

  postInstall = ''
    mkdir -p $out/bin
    ln -srf $out/share/tmux-plugins/tmux-claude-status/hooks/better-hook.sh $out/bin/tmux-claude-status-hook
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta = {
    homepage = "https://github.com/samleeney/tmux-claude-status";
    description = "Handy plugin to create toggleable popups";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
