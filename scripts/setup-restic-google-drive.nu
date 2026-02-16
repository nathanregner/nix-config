#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nushell sops rclone

def main [host: string] {
  let creds = (
    sops -d $"(git rev-parse --show-toplevel)/secrets.yaml"
    | from yaml
  )

  let client_id = $creds.google_drive.oauth_client_id
  let client_secret = $creds.google_drive.oauth_client_secret

  if ($client_id | is-empty) or ($client_secret | is-empty) {
    error make "Failed to get OAuth credentials"
  }

  print $"Client ID: ($client_id)"

  let token = (
    rclone authorize "drive"
    --drive-scope "drive.file"
    $client_id
    $client_secret
    | complete
    | get stdout
    | parse --regex '(?s)--->\s*(\{.*?\})\s*<---'
    | get capture0.0
  )

  if ($token | is-empty) {
    error make "Failed to get OAuth token"
  }

  print "\nToken acquired successfully"

  print $"Configuring rclone on ($host)..."

  (
    $"[google_drive]
    type = drive
    client_id = ($client_id)
    client_secret = ($client_secret)
    scope = drive.file
    token = ($token)
    team_drive ="
    | ssh $host "sudo mkdir -p /root/.config/rclone && sudo tee /root/.config/rclone/rclone.conf > /dev/null"
  )

  print "\nTesting connection..."
  let test_result = (
    ssh $host "sudo rclone lsd google_drive: 2>&1"
    | complete
  )

  if $test_result.exit_code == 0 {
    print "✓ Connection successful"
    print $"\nSetup complete! Start backup with:"
    print $"  ssh ($host) sudo systemctl start restic-backups-nixos-google-drive.service"
  } else {
    print "✗ Connection test failed"
    print $test_result.stdout
    print $test_result.stderr
    exit 1
  }
}
