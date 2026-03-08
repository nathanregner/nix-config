# derived from https://github.com/tintinweb/claude-code-container/blob/master/claude-standalone/run_claude.sh
{
  writeShellApplication,
  docker,
  callPackage,
}:
let
  image = callPackage ./image.nix { };
in
writeShellApplication {
  name = "claude-docker";
  runtimeInputs = [ docker ];
  text = ''
    DEBUG=false
    for arg in "$@"; do
      if [[ "$arg" == "--debug" ]]; then
        DEBUG=true
      fi
    done

    WORKSPACE_DIR="$(pwd)"

    # Image tag derived from nix derivation hash
    IMAGE_TAG="${image.imageTag}"
    IMAGE_NAME="claude-docker:$IMAGE_TAG"

    # Load image if not already present
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
      docker load < ${image}
    fi

    DOCKER_ARGS=(
      "run" "-it" "--rm"
      # # Run as current user
      "--user" "$(id -u):$(id -g)"
      # Security: Drop all capabilities
      "--cap-drop=ALL"
      # Security: Prevent privilege escalation
      "--security-opt=no-new-privileges:true"
      # Security: Non-executable temp filesystem
      "--tmpfs" "/tmp:noexec,nosuid,size=100m"
      # Security: Limit PIDs to prevent fork bombs
      "--pids-limit=100"
      # Security: Restrict network to external only
      "--network=bridge"
      # Mount workspace at same path structure
      "-v" "$WORKSPACE_DIR:/$WORKSPACE_DIR:rw"
      "-w" "$WORKSPACE_DIR"
      # Nix profile (readonly)
      "-v" "$(realpath "$HOME/.nix-profile"):$HOME/.nix-profile:ro"
      "-v" "$HOME/.config/zsh/.zshrc:$HOME/.zshrc:ro"
      "-v" "$HOME/.config/zsh/.zshenv:$HOME/.zshenv:ro"
      # Claude config (read-write)
      "-v" "$HOME/.claude:$HOME/.claude:rw"
      "-v" "$HOME/.claude.json:$HOME/.claude.json:rw"
      # Nix store overlay mount (host store as lower layer)
      # "-v" "/nix/store:/mnt/nix-overlay/store-host:ro"
      # "-v" "claude-nix-store:/mnt/nix-overlay/upper"
      # Nix store (readonly, shared from host)
      "-v" "/nix/store:/nix/store:ro"
    )

    if [[ "$DEBUG" == "true" ]]; then
      docker "''${DOCKER_ARGS[@]}" "$IMAGE_NAME" /bin/bash
    else
      docker "''${DOCKER_ARGS[@]}" "$IMAGE_NAME"
    fi
  '';
  passthru = { inherit image; };
}
