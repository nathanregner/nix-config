{
  local.users.craigslist = { };

  virtualisation.podman.enable = true;

  # https://github.com/containers/podman/discussions/23193
  environment.etc."tmpfiles.d/podman.conf".text = ''
    R! /tmp/storage-run-*/containers/
    R! /tmp/storage-run-*/libpod/tmp/
    R! /tmp/containers-user-*/containers
    R! /tmp/podman-run-*/libpod/tmp
  '';

  nginx.subdomain = {
    craigslist."/".proxyPass = "http://127.0.0.1:8888/";
    craigslist-api."/".proxyPass = "http://127.0.0.1:6000/";
  };
}
