terraform -chdir=infrastructure/ddns output -json \
  | jq -r '.aws_env.value | to_entries | .[]
    | "sops --set '\''[\"route53-ddns\"][\"env\"] \(.value)'\'' machines/\(.key)/secrets.yaml"' \
  | bash
