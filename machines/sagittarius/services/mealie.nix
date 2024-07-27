{ sources, ... }:
let
  hostPort = 9000;
  dataDir = "/var/lib/mealie";
in
{
  virtualisation.oci-containers.containers.mealie = rec {
    imageFile = sources.mealie.src;
    image = "${imageFile.imageName}@${imageFile.imageDigest}";
    # https://docs.mealie.io/documentation/getting-started/installation/sqlite/
    environment = {
      BASE_URL = "https://mealie.nregner.net";
      DATA_DIR = dataDir;
    };
    ports = [ "${toString hostPort}:9000" ];
    volumes = [ "${dataDir}:${dataDir}" ];
  };

  nginx.subdomain.mealie = {
    "/".proxyPass = "http://127.0.0.1:${toString hostPort}/";
  };

  services.nregner.backups.mealie = {
    paths = [ dataDir ];
    restic = {
      s3 = { };
    };
  };
}
