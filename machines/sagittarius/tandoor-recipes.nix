{ config, ... }: {
  services.tandoor-recipes = {
    enable = true;
    # address = "0.0.0.0";
    port = 8081;
    # https://raw.githubusercontent.com/vabene1111/recipes/master/.env.template
    extraConfig = {
      TIMEZONE = "America/Boise";
      ALLOWED_HOSTS = "*";
    };
  };

  nginx.subdomain.recipes = {
    "/".proxyPass =
      "http://127.0.0.1:${toString config.services.tandoor-recipes.port}/";
  };
}
