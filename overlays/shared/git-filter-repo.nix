prev: pkg:
# FIXME: Remove once https://github.com/newren/git-filter-repo/issues/659 is released
pkg.overrideAttrs (_oldAttrs: {
  src = prev.fetchFromGitHub {
    owner = "newren";
    repo = "git-filter-repo";
    rev = "2d391462dca14cd18b8faaefce34dc91dc1ae150";
    hash = "sha256-2jws/s36GuZrthODzj3OvlR9lDU9Nr1XIGNWRyO+0wA=";
  };

  checkPhase = ''
    make test
  '';
})
