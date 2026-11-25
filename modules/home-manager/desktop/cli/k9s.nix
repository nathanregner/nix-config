{ config, pkgs, ... }:
{
  catppuccin.k9s.enable = true;
  programs.k9s = {
    enable = true;
    package = pkgs.unstable.k9s;

    views = {
      "v1/pods" = {
        columns = [
          "NAMESPACE"
          "NAME"
          "VERSION:.metadata.labels.tags\\.datadoghq\\.com/version"
          "VS"
          "PF"
          "READY"
          "STATUS"
          "RESTARTS"
          "LAST RESTART"
          "CPU"
          "CPU/RL"
          "%CPU/R"
          "%CPU/L"
          "MEM"
          "MEM/RL"
          "%MEM/R"
          "%MEM/L"
          "GPU/RL"
          "IP"
          "NODE"
          "SERVICE-ACCOUNT"
          "NOMINATED NODE"
          "READINESS GATES"
          "QOS"
          "LABELS"
          "VALID"
          "AGE"
        ];
      };
      "apps/v1/deployments" = {
        columns = [
          "NAMESPACE"
          "NAME"
          "VERSION:.metadata.labels.tags\\.datadoghq\\.com/version"
          "VS"
          "READY"
          "UP-TO-DATE"
          "AVAILABLE"
          "LABELS"
          "VALID"
          "AGE"
        ];
      };
    };
  };

  xdg.enable = true;

  # lazy fix for mismatched config path on darwin
  imports = [
    (
      { pkgs, lib, ... }:
      {
        config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          home.file."Library/Application Support/k9s".source =
            config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/k9s";
        };
      }
    )
  ];
}
