{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    catppuccin.enable = true;
    # https://starship.rs/config
    settings = {
      aws.disabled = true;
      nix_shell = {
        symbol = "❄️";
        heuristic = true;
      };
      docker_context.only_with_files = false;
      package.disabled = true;
    };
  };
}
