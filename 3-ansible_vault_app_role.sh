#!/bin/bash

set -e  # Exit on error

echo "Starting Vault AppRole configuration..."

# Log in to Vault
export VAULT_ADDR="https://localhost:8201"
export VAULT_SKIP_VERIFY=true
unset VAULT_TOKEN
echo "Logging into Vault..."
vault login

echo "Vault login successful."

# Enable AppRole authentication if not already enabled
if vault auth list | grep -q "approle/"; then
    echo "AppRole auth method already enabled. Skipping..."
else
    echo "Enabling Vault AppRole authentication..."
    vault auth enable approle
fi

# Create a Vault policy for AppRole
echo "Creating Vault policy for AppRole..."
cat <<EOF > approle-policy.hcl
path "mytest/data/*" {
    capabilities = ["read", "list"]
}

path "mytest/metadata/*" {
    capabilities = ["read", "list"]
}
EOF

vault policy write approle-policy approle-policy.hcl
echo "Vault policy created."

# Create an AppRole with the policy
ROLE_NAME="ansible-approle"
echo "Creating AppRole: $ROLE_NAME"
vault write auth/approle/role/$ROLE_NAME \
    token_policies="approle-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    secret_id_num_uses=10 \
    secret_id_ttl=1h

echo "AppRole created."

# Retrieve the Role ID
ROLE_ID=$(vault read -field=role_id auth/approle/role/$ROLE_NAME/role-id)
echo "Retrieved Role ID: $ROLE_ID"

# Generate and retrieve the Secret ID
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/$ROLE_NAME/secret-id)
echo "Retrieved Secret ID: $SECRET_ID"

echo "AppRole authentication setup and configuration completed successfully."
