#!/bin/bash

set -e  # Exit on error

export VAULT_ADDR="https://localhost:8201"
export VAULT_SKIP_VERIFY=true  # Skip SSL verification if using self-signed certs

VAULT_SECRET_PATH="mytest/mytest"
APPROLE_NAME="ansible-approle"  # Update this to match your AppRole name

echo "--------------------------------"
echo "  Authenticating to Vault using Certificate Authentication"
echo "--------------------------------"

# Login using Certificate Authentication and extract the Vault token
VAULT_TOKEN=$(vault login -method=cert \
    -client-cert=tls/tls-cert.pem \
    -client-key=tls/tls-key.pem \
    -format=json | jq -r '.auth.client_token')

export VAULT_TOKEN
echo "Vault login successful."

echo "--------------------------------"
echo "  Fetching AppRole Credentials"
echo "--------------------------------"

# Retrieve AppRole Role ID dynamically
ROLE_ID=$(vault read -field=role_id auth/approle/role/$APPROLE_NAME/role-id)

# Generate a new Secret ID dynamically
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/$APPROLE_NAME/secret-id)

echo "--------------------------------"
echo "  Fetching Secret from Vault using AppRole"
echo "--------------------------------"

# Authenticate using AppRole and retrieve a new token
APPROLE_TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")

# Use the new token for Vault operations
export VAULT_TOKEN=$APPROLE_TOKEN

# Fetch secret
vault kv get $VAULT_SECRET_PATH

echo "--------------------------------"
echo "Vault Secret retrieval completed successfully."
