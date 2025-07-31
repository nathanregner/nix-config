{
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule rec {
  name = "duplik8s";
  version = "0.5.1";
  src = fetchFromGitHub {
    owner = "Telemaco019";
    repo = "duplik8s";
    rev = "v${version}";
    hash = "sha256-8y+vhRDyi3p1JZqjIMHyiHaD+FJa231dPc1on+hA13k=";
  };

  vendorHash = "sha256-0sanu5TCdJEIT8mkgrgv0P3ewhwAezJQAZuQTR2DClM=";

  passthru.updateScript = nix-update-script { };
}
