{ pkgs, ... }:
{
  programs.awscli = {
    enable = true;
    package = pkgs.unstable.awscli2;
    settings = {
      default = {
        sso_session = "main";
        sso_account_id = "544292031362";
        sso_role_name = "AdministratorAccess";
        region = "us-west-2";
        output = "json";
      };
      "sso-session main" = {
        sso_start_url = "https://d-92677d606c.awsapps.com/start";
        sso_region = "us-west-2";
        sso_registration_scopes = "sso:account:access";
      };
    };
  };
}
