let
  blacklist = {
    # https://github.com/NixOS/nixpkgs/issues/576485
    security.pki.caCertificateBlacklist = [
      "Comodo AAA Services root"
      "emSign ECC Root CA - G3"
      "emSign Root CA - G1"
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
