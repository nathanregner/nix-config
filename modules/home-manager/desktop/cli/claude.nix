{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.programs.claude-code.merged-hooks = mkOption {
    type = types.attrsOf (
      lib.types.listOf (
        lib.types.submodule {
          options = {
            command = mkOption { type = lib.types.str; };
          };
        }
      )
    );
  };

  config = {
    programs.claude-code = {
      enable = true;
      package = pkgs.unstable.claude-code;

      mcpServers = {
        github = {
          type = "stdio";
          command = lib.getExe pkgs.github-mcp-server;
          args = [ "stdio" ];
        };

        playwright = {
          type = "stdio";
          command = lib.getExe pkgs.playwright-mcp;
        };
      };

      # https://code.claude.com/docs/en/settings
      settings = {
        hooks = lib.mapAttrs (
          _: hooks:
          (map (hook: {
            matcher = "";
            hooks = [
              {
                type = "command";
                inherit (hook) command;
              }
            ];
          }) hooks)
        ) config.programs.claude-code.merged-hooks;
        model = "claude-opus-4-5";
        availableModels = [
          "claude-sonnet-4-5"
          "claude-opus-4-5"
          "haiku"
        ];
        statusLine = {
          type = "command";
          command = "${config.home.homeDirectory}/.claude/statusline";
        };
        env = {
          ENABLE_TOOL_SEARCH = "true"; # lazy-load MCPs
        };
        permissions = {
          defaultMode = "acceptEdits";
          allow = [
            "Bash(cargo clean:*)"
            "Bash(cargo doc:*)"
            "Bash(cargo info:*)"
            "Bash(cargo tree:*)"
            "Bash(cat:*)"
            "Bash(echo:*)"
            "Bash(git cp:*)"
            "Bash(git diff:*)"
            "Bash(git mv:*)"
            "Bash(grep:*)"
            "Bash(ls:*)"
            "Bash(tree:*)"
            "Read(/nix/store/**)"
            "Read(~/.cargo/registry/**)"
            "WebFetch"
            "WebSearch"
            "mcp__ide__getDiagnostics"
          ];
          ask = [
          ];
          deny = [
            "Read(**/*.key)"
            "Read(**/*.pem)"
            "Read(**/.aws/**)"
            "Read(**/.env*)"
            "Read(**/.ssh/**)"
            "Read(**/secrets/**)"
          ];
        };
        sandbox = {
          enable = true;
          filesystem = rec {
            denyRead = [ "/" ]; # deny by default
            # anything writable must also be readable
            allowRead = [
              "/nix/store"
              "~/configs"
              "~/dev"
              # ~/.nix-profile/bin/git resolves through this symlink chain;
              # without it git falls back to the /usr/bin xcode-select stub
              "~/.nix-profile"
              "~/.local/state/nix/profiles"
              "~/.config/git"
              "~/.npmrc"
              "/tmp"
            ]
            ++ lib.optionals pkgs.stdenv.isDarwin [
              "/bin"
              "/private/tmp" # TODO
              "/var/select/developer_dir"
              "~/Library/Java" # JAVA_HOME; maven launches $JAVA_HOME/bin/java
              # the JVM reads the OS version from this plist at boot; without it
              # os.version resolves to -1.0 and the boot layer fails to initialize
              "/System/Library/CoreServices/SystemVersion.plist"
              "/System/Library/CoreServices/.SystemVersionPlatform.plist"
            ]
            ++ allowWrite;
            allowWrite = [
              # TODO
              /*
                 Error: Exit code 1
                 Auto configuration failed
                 8515903104:error:02FFF001:system library:func(4095):Operation not permitted:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sour
                 ces/libressl/libressl-3.3/crypto/bio/bss_file.c:122:fopen('/private/etc/ssl/openssl.cnf', 'rb')
                 8515903104:error:20FFF002:BIO routines:CRYPTO_internal:system
                 lib:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sources/libressl/libressl-3.3/crypto/bio/bss_file.c:127:
                 8515903104:error:0EFFF002:configuration file routines:CRYPTO_internal:system
                 lib:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sources/libressl/libressl-3.3/crypto/conf/conf_def.c:202:
                 Auto configuration failed
                 8515903104:error:02FFF001:system library:func(4095):Operation not permitted:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sour
                 ces/libressl/libressl-3.3/crypto/bio/bss_file.c:122:fopen('/private/etc/ssl/openssl.cnf', 'rb')
                 8515903104:error:20FFF002:BIO routines:CRYPTO_internal:system
                 lib:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sources/libressl/libressl-3.3/crypto/bio/bss_file.c:127:
                 8515903104:error:0EFFF002:configuration file routines:CRYPTO_internal:system
                 lib:/AppleInternal/Library/BuildRoots/4~CNqEugB7-7yoTeHDwKLZ0PRIsI79y9XP33qXeIo/Library/Caches/com.apple.xbs/TemporaryDirectory.MoIAiI/Sources/libressl/libressl-3.3/crypto/conf/conf_def.c:202:
              */
              "/tmp" # TODO
              "~/.cache/node"
              "~/.cache/pnpm"
              "~/.cache/yarn"
              "~/.local/share/colim"
              "~/.local/share/pnpm"
              "~/.local/share/yarn"
              "~/.m2"
            ];
          };
        };
      };
    };

    home.file.".claude/statusline".source = config.lib.file.mkFlakeSymlink ./claude-statusline.nu;

    programs.git.ignores = [
      ".claude"
    ];

    programs.zsh = {
      enable = true;
      initContent = lib.optionalString config.programs.direnv.enable /* zsh */ ''
        if [[ ! -z "$CLAUDECODE" ]]; then
          eval "$(direnv hook zsh)"
          eval "$(DIRENV_LOG_FORMAT= direnv export zsh)"  # Need to trigger "hook" manually
        fi
      '';
    };
  };
}
