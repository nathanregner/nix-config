# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ inputs, pkgs }: {
  gitea-github-mirror = pkgs.unstable.callPackage ./gitea-github-mirror { };

  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };

  netdata-latest = pkgs.unstable.callPackage ./netdata.nix { };

  conform-nvim = pkgs.unstable.vimUtils.buildVimPlugin {
    pname = "conform.nvim";
    version = inputs.conform-nvim.rev;
    src = inputs.conform-nvim;
    meta.homepage = "https://github.com/stevearc/conform.nvim";
    # the Makefile non-deterministically pulls git repos for linting/testing - don't need it
    postPatch = "rm Makefile";
  };
}
