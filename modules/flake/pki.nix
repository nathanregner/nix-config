let
  blacklist = {
    # https://github.com/NixOS/nixpkgs/issues/576485
    security.pki.caCertificateBlacklist = [
      # CVE-2026-111943
      "Comodo AAA Services root"
      # # https://hg-edge.mozilla.org/projects/nss/rev/26d38a0c3fb81e7fb2acedbaf4c42dd21dce0517
      # "emSign ECC Root CA - G3"
      # # https://hg-edge.mozilla.org/projects/nss/rev/8159223c48ceeb1273a1915bca95a517294ab0e0
      # "emSign Root CA - C1"
      # "emSign ECC Root CA - C3"
    ];
  };
in
{
  flake.modules.nixos.pki = blacklist;

  flake.modules.darwin.pki = {
    imports = [ blacklist ];

    # macOS owns /etc/ssl/cert.pem and may overwrite it on update, so point TLS clients at the nix bundle.
    environment.variables = {
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}
