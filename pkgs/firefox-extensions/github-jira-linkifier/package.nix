{
  fetchFromGitHub,
  mkFirefoxExtension,
}:
mkFirefoxExtension rec {
  pname = "github-jira-linkifier@nregner.net";
  version = "728488028fbb753437402de8ea6292baff57b4cf";
  src = fetchFromGitHub {
    owner = "jefgen";
    repo = "github-jira-linkifier-webextension";
    rev = "728488028fbb753437402de8ea6292baff57b4cf";
    fetchSubmodules = false;
    sha256 = "sha256-SSi33oCP52C1etTg2rVz3YQ41HWOpsgmXDwEgbkxHq4=";
  };
  sourceRoot = "${src.name}/src";

  postPatch = ''
    substituteInPlace manifest.json \
      --replace-fail 'github.com' 'git.clickbank.io'
    substituteInPlace background.js \
      --replace-fail 'span.js-issue-title' 'bdi.js-issue-title'
  '';

}
