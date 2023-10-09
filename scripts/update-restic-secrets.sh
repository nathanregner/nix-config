terraform -chdir=infrastructure/restic output -json \
  | jq -r '.secrets.value | to_entries | .[]
    | "sops --set '\''[\"restic\"] \(.value)'\'' machines/\(.key)/secrets.yaml"' \
  | bash
