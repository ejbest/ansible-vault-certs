#!/bin/bash -x
#vault-unseal-nodes.sh

# List of Vault node API addresses
VAULT_NODES=("172.18.0.12:28200" "172.18.0.13:38200")

# Read unseal threshold
UNSEAL_THRESHOLD=$(jq -r '.unseal_threshold' run/vault-operator-init.json)

# Loop through each Vault node
for NODE in "${VAULT_NODES[@]}"; do
  export VAULT_ADDR="http://$NODE"
  echo "Unsealing node: $VAULT_ADDR"

  for i in $(seq 0 $((UNSEAL_THRESHOLD - 1))); do
    KEY=$(jq -r --argjson i "$i" '.unseal_keys_b64[$i]' run/vault-operator-init.json)
    vault operator unseal "$KEY"
  done
done
