{
  # https://nix-darwin.github.io/nix-darwin/manual/index.html
  # defaults read  ~/Library/Preferences/.GlobalPreferences
  system.defaults = {
    NSGlobalDomain = {
      "com.apple.keyboard.fnState" = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
    };

    finder = {
      FXDefaultSearchScope = "SCcf";
      _FXShowPosixPathInTitle = true;
    };

    menuExtraClock.ShowSeconds = true;

    # CustomUserPreferences =
    #   lib.trivial.pipe (lib.filesystem.listFilesRecursive ./preferences) [
    #     (builtins.filter
    #       (path: (builtins.match ".*.json" (builtins.toString path)) != null))
    #     (builtins.map (path: (builtins.fromJSON (builtins.readFile path))))
    #     lib.mkMerge
    #   ];
  };
}
