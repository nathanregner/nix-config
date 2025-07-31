{
  buildGoModule,
  fetchFromGitHub,
  fetchpatch2,
  nix-update-script,
}:
buildGoModule rec {
  name = "kubectl-duplicate";
  version = "0.2.1";
  src = fetchFromGitHub {
    owner = "qonto";
    repo = "kubectl-duplicate";
    rev = "v${version}";
    hash = "sha256-uYbsowyvNTu6DXVMedIYaAboQhijg8qrFpJVjVspimc=";
  };

  patches = [
    (fetchpatch2 {
      url = "https://github.com/qonto/kubectl-duplicate/pull/3/commits/3857e721c9fc15db36c57257776aca396d50faed.patch";
      hash = "sha256-vmZw4K+gVdEXBvPo1l4v+TO0nFkI14LhcQslcsL0s54=";
    })
  ];

  vendorHash = "sha256-4hi1T9CUHCH+ZoQwPG/jJX6KWmB4Hd9v7y7x6Gk188c=";

  passthru.updateScript = nix-update-script { };
}
