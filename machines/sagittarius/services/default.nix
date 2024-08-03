{
  imports = [
    ../../../modules/nixos/github-actions/github.nix
    ./docker.nix
    ./elk.nix
    ./gitea.nix
    ./hydra.nix
    ./k8s.nix
    ./mealie.nix
    ./nexus.nix
    ./nginx.nix
    ./nix-serve.nix
    ./qbittorrent.nix
  ];
}
