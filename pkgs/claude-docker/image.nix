{
  runtimeShell,
  dockerTools,
  buildEnv,
  writeTextDir,
  bashInteractive,
  coreutils,
  nix,
  cacert,
}:
let
  nixConf = writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
  '';
  # experimental-features = nix-command flakes local-overlay-store
  # store = local-overlay://?root=/nix/store&lower-store=/mnt/nix-overlay/store-host&upper-layer=/mnt/nix-overlay/upper&check-mount=false

  passwd = writeTextDir "etc/passwd" ''
    root:x:0:0:root:/root:/bin/bash
    nregner:x:1000:100:nregner:/home/nregner:/bin/bash
  '';

  group = writeTextDir "etc/group" ''
    root:x:0:
    users:x:100:nregner
  '';
in
dockerTools.buildLayeredImage {
  name = "claude-docker";
  # tag derived from content hash for cache invalidation

  contents = buildEnv {
    name = "claude-docker-env";
    paths = [
      bashInteractive
      coreutils
      nix
      cacert
      nixConf
      # passwd
      # group
      dockerTools.caCertificates
    ];
    pathsToLink = [
      "/bin"
      "/etc"
    ];
  };

  fakeRootCommands = ''
    ${dockerTools.shadowSetup}
    groupadd -g 100 users
    useradd -u 1000 -g 100 -m nregner
    mkdir -p /home/nregner
    chown -R nregner:users /home/nregner
  '';
  enableFakechroot = true;

  config = {
    User = "1000:100";
    Env = [
      "PATH=/bin:/home/nregner/.nix-profile/bin"
      "HOME=/home/nregner"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
