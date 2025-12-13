{
  programs.claude-code = {
    enable = true;

    settings = {
      model = "sonnet";
      permissions = {
        defaultMode = "acceptEdits";

        allow = [
          "Bash(cargo b:*)"
          "Bash(cargo clean:*)"
          "Bash(cargo doc:*)"
          "Bash(cargo info:*)"
          "Bash(cargo tree:*)"
          "Bash(cat :*)"
          "Bash(echo :*)"
          "Bash(git cp:*)"
          "Bash(git diff:*)"
          "Bash(git mv:*)"
          "Read(/nix/store/**)"
          "Read(~/.cargo/registry/**)"
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
    };
  };

  programs.git.ignores = [
    "settings.local.json"
  ];
}
