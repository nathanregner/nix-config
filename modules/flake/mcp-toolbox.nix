{ ... }:
{
  flake.modules.homeManager.mcp-toolbox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # serverPort is the mcp-toolbox HTTP listen port.
      # dbs mirrors the shape used in mkConfig / mkServerScript.
      databases = {
        prod = {
          serverPort = 5000;
          dbs = [
            {
              name = "useradmin";
              host = "127.0.0.1";
              port = "3442";
              user = "nathan.regner";
              passwordEnv = "NREGNER_PASSWORD";
            }
          ];
        };
        dev = {
          serverPort = 5001;
          dbs = [
            {
              name = "useradmin";
              host = "tstdb-ro.clickbank-tst.net";
              user = "svc_useradmin_ro";
              passwordEnv = "USERADMIN_RO_PASSWORD";
            }
          ];
        };
      };

      mkConfig =
        dbs:
        let
          sources = builtins.listToAttrs (
            map (db: {
              name = "${db.name}-ro";
              value = {
                kind = "mysql";
                inherit (db) host user;
                port = lib.toInt (toString (db.port or 3306));
                database = db.name;
                password = "\${${db.passwordEnv}}";
              };
            }) dbs
          );
          tools = builtins.listToAttrs (
            builtins.concatMap (db: [
              {
                name = "${db.name}_list_tables";
                value = {
                  kind = "mysql-sql";
                  source = "${db.name}-ro";
                  description = "List all tables in the ${db.name} database";
                  statement = "SHOW TABLES";
                };
              }
              {
                name = "${db.name}_execute_sql";
                value = {
                  kind = "mysql-sql";
                  source = "${db.name}-ro";
                  description = "Execute a SQL query against the ${db.name} database. Use this for SELECT queries to explore data.";
                  templateParameters = [
                    {
                      name = "sql";
                      type = "string";
                      description = "The SQL query to execute";
                    }
                  ];
                  statement = "{{.sql}}";
                };
              }
            ]) dbs
          );
        in
        pkgs.writeText "mcp-toolbox.yaml" (lib.generators.toYAML { } { inherit sources tools; });

      mkServerScript =
        env:
        { serverPort, dbs }:
        let
          configDir = pkgs.linkFarm "mcp-toolbox-config-${env}" [
            {
              name = "tools.yaml";
              path = mkConfig dbs;
            }
          ];
        in
        pkgs.writeShellScript "mcp-toolbox-${env}-server" ''
          set -o allexport
          source ${lib.escapeShellArg config.sops.secrets.mcp-toolbox-env.path}
          set +o allexport
          exec ${lib.getExe pkgs.local.mcp-toolbox} \
            --config "${configDir}/tools.yaml" \
            --port ${toString serverPort}
        '';

      mcpToolboxPermissions = lib.concatLists (
        lib.mapAttrsToList (
          env: { dbs, ... }:
          builtins.concatMap (db: [
            "mcp__mcp-toolbox-${env}__${db.name}_execute_sql"
            "mcp__mcp-toolbox-${env}__${db.name}_list_tables"
          ]) dbs
        ) databases
      );
    in
    {
      programs.claude-code = {
        mcpServers = lib.mapAttrs' (env: { serverPort, ... }: {
          name = "mcp-toolbox-${env}";
          value = {
            type = "http";
            url = "http://127.0.0.1:${toString serverPort}/mcp";
          };
        }) databases;

        settings.permissions.allow = mcpToolboxPermissions;
      };

      # Darwin: launchd agents restart the server when sops rotates the secret.
      launchd.agents = lib.mkIf pkgs.stdenv.isDarwin (
        lib.mapAttrs' (env: envCfg: {
          name = "mcp-toolbox-${env}";
          value = {
            enable = true;
            config = {
              ProgramArguments = [ (toString (mkServerScript env envCfg)) ];
              KeepAlive = true;
              RunAtLoad = true;
              WatchPaths = [
                config.sops.defaultSymlinkPath
                config.sops.secrets.mcp-toolbox-env.path
              ];
              StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mcp-toolbox-${env}.log";
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mcp-toolbox-${env}.log";
            };
          };
        }) databases
      );

      # Linux: systemd user services.
      systemd.user.services = lib.mkIf pkgs.stdenv.isLinux (
        lib.mapAttrs' (env: envCfg: {
          name = "mcp-toolbox-${env}";
          value = {
            Unit = {
              Description = "MCP Toolbox ${env} server";
              After = [ "sops-nix.service" ];
            };
            Service = {
              ExecStart = toString (mkServerScript env envCfg);
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        }) databases
      );

      sops.secrets.mcp-toolbox-env.key = "mcp-toolbox.env";
    };
}
