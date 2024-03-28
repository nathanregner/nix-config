{
  system.defaults = {
    # defaults read  ~/Library/Preferences/.GlobalPreferences
    NSGlobalDomain = {
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;
      "com.apple.keyboard.fnState" = true;
    };

    finder = {
      FXDefaultSearchScope = "SCcf";
      _FXShowPosixPathInTitle = true;
    };

    # CustomUserPreferences =
    #   lib.trivial.pipe (lib.filesystem.listFilesRecursive ./preferences) [
    #     (builtins.filter
    #       (path: (builtins.match ".*.json" (builtins.toString path)) != null))
    #     (builtins.map (path: (builtins.fromJSON (builtins.readFile path))))
    #     lib.mkMerge
    #   ];
  };

  # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
  system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
