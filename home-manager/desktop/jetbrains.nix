{ pkgs, ... }: {
  home.packages = with pkgs.unstable; [
    jetbrains-toolbox
    rustup # can IntelliJ just get this from direnv somehow?
    stdenv.cc # can IntelliJ just get this from direnv somehow?
  ];

  home.file.".vimrc".source = ./vimrc;
  home.file.".ideavimrc".source = ./ideavimrc;
}

