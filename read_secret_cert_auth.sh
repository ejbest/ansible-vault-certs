#!/bin/bash

set -e  # Exit on error

export VAULT_ADDR="https://localhost:8201"
export VAULT_SKIP_VERIFY=true  # Skip SSL verification if using self-signed certs

VAULT_SECRET_PATH="mytest/mytest"

echo "--------------------------------"
echo "  Reading Secret from Vault"
echo "--------------------------------"

### 1️⃣ Certificate Authentication
echo "Logging into Vault using Certificate Authentication..."
vault login -method=cert \
    -client-cert=tls/tls-cert.pem \
    -client-key=tls/tls-key.pem

echo "Fetching secret using Cert Auth..."
vault kv get $VAULT_SECRET_PATH

echo "--------------------------------"

### 2️⃣ AppRole Authentication
# Replace with actual Role ID and Secret ID
ROLE_ID="b8501061-a3aa-8ac7-77f0-aeacc026d55c"
SECRET_ID="2fa4e9d4-d28b-24fb-bba0-b26f18d40894"

echo "Logging into Vault using AppRole..."
VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")

# Export token for session use
export VAULT_TOKEN

echo "Fetching secret using AppRole Auth..."
vault kv get $VAULT_SECRET_PATH

echo "--------------------------------"
echo "Vault Secret retrieval completed successfully."
