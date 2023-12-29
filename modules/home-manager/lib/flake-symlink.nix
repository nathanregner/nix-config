{ config, lib, ... }: {
  options = {
    home.flakePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        If non-empty, `mkFlakeSymlink` will create symlinks to flake-relative paths (as opposed to adding them to the nix store).
        Allows for faster iteration of config file changes.

        Inspired by https://github.com/nix-community/home-manager/issues/208
      '';
    };
  };

  config = {
    lib.file.mkFlakeSymlink = (path:
      assert lib.assertMsg (builtins.isPath path)
        "Argument is of type ${builtins.typeOf path}, but a path was expected'";

      if config.home.flakePath != "" then
        config.lib.file.mkOutOfStoreSymlink "${config.home.flakePath}/${
          lib.head (builtins.match "/nix/store/[^/]+/(.*)" (toString path))
        }"
      else
        path);
  };
}

