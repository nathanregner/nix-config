{ pkgs, ... }: {
  home.packages = with pkgs.unstable;
  # TODO: can IntelliJ just get this from direnv somehow?
    [ rustup ] ++ lib.optionals stdenv.isLinux [ jetbrains-toolbox ];

  home.file.".vimrc".source = ./vimrc;
  home.file.".ideavimrc".source = ./ideavimrc;
}

