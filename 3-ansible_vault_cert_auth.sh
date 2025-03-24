#!/bin/bash

set -e  # Exit on error

# Log in to Vault using a token
export VAULT_ADDR="https://localhost:8201"
export VAULT_SKIP_VERIFY=true
unset VAULT_TOKEN
echo "Logging into Vault using token..."
vault login

echo "Vault login successful."

# Check if KV2 secrets engine at path 'mytest' already exists
if vault secrets list | grep -q "mytest/"; then
    echo "KV2 secrets engine 'mytest' already enabled. Skipping..."
else
    echo "Enabling KV2 secrets engine at 'mytest'..."
    vault secrets enable -path=mytest kv-v2
fi

# Create test KV2 secret
vault kv put mytest/mytest name=EJ-123

# Check if cert auth method already exists
if vault auth list | grep -q "cert/"; then
    echo "Cert auth method already enabled. Skipping..."
else
    echo "Enabling Vault cert auth method..."
    vault auth enable cert
fi

# Create a Vault policy for Ansible
echo "Creating Vault policy for Ansible..."
cat <<EOF > ansible-policy.hcl
path "mytest/data/*" {
    capabilities = ["read", "list"]
}

path "mytest/metadata/*" {
    capabilities = ["read", "list"]
}
EOF

vault policy write ansible ansible-policy.hcl
echo "Vault policy created."

# Register the Certificate with Vault
echo "Registering certificate with Vault..."
vault write auth/cert/certs/ansible-client \
    display_name="ansible-client" \
    policies="ansible" \
    certificate=@tls/tls-ca.pem
echo "Certificate registered with Vault."

echo "Vault authentication setup and configuration completed successfully."
