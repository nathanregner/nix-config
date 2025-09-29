{
  # https://nix-darwin.github.io/nix-darwin/manual/index.html
  # defaults read  ~/Library/Preferences/.GlobalPreferences
  system.defaults = {
    CustomUserPreferences = {
      NSGlobalDomain = {
        ApplePersistence = false;
      };
    };

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

    CustomUserPreferences = {
      # disable indexing of everything but apps
      "com.apple.Spotlight" = {
        EnabledPreferenceRules = [
          "com.apple.AppStore"
          "com.apple.iBooksX"
          "com.apple.calculator"
          "com.apple.iCal"
          "com.apple.AddressBook"
          "com.apple.Dictionary"
          "com.apple.mail"
          "com.microsoft.Outlook"
          "com.apple.Notes"
          "com.apple.Photos"
          "com.apple.podcasts"
          "com.apple.reminders"
          "com.apple.Safari"
          "com.apple.shortcuts"
          "com.apple.systempreferences"
          "com.apple.tips"
          "com.apple.VoiceMemos"
          "System.documents"
          "System.folders"
          "System.iphoneApps"
          "System.menuItems"
        ];
      };
    };

    # CustomUserPreferences =
    #   lib.trivial.pipe (lib.filesystem.listFilesRecursive ./preferences) [
    #     (builtins.filter
    #       (path: (builtins.match ".*.json" (builtins.toString path)) != null))
    #     (builtins.map (path: (builtins.fromJSON (builtins.readFile path))))
    #     lib.mkMerge
    #   ];
  };
}
