#!/bin/bash

set -e  # Exit on error

mkdir -p vault-tls

# Generate a Root CA Certificate (ca.pem)
echo "Generating Root CA Certificate..."
openssl genrsa -out vault-tls/ca-bundle.key 4096
openssl req -x509 -new -nodes -key vault-tls/ca-bundle.key -sha256 -days 365 -out vault-tls/ca-bundle.crt -subj "/CN=Vault"
echo "Root CA Certificate generated."

# Generate a New Client Certificate Signed by CA
echo "Generating Client Key..."
openssl genrsa -out vault-tls/vaul_ssl_key 4096
echo "Client Key generated."

# Create a Certificate Signing Request (CSR)
echo "Creating CSR..."
openssl req -new -key vault-tls/vaul_ssl_key -out vault-tls/vault_ssl_bundle -subj "/CN=vault" \
-addext "subjectAltName =  DNS:vault, DNS:vault-node-1, DNS:vault-node-2, DNS:vault-node-3, DNS:vault-node-4, DNS:vault-node-5"
echo "CSR created."

# Sign the Client Cert Using Your CA
echo "Signing Client Certificate..."
openssl x509 -req -in vault-tls/vault_ssl_bundle -CA vault-tls/ca-bundle.crt -CAkey vault-tls/ca-bundle.key -CAcreateserial \
-out vault-tls/vault_ssl_bundle -days 365 -sha256 \
-extfile <(printf "subjectAltName= DNS:vault, DNS:vault-node-1, DNS:vault-node-2, DNS:vault-node-3, DNS:vault-node-4, DNS:vault-node-5")
echo "Client Certificate signed."

echo "TLS certificate setup completed successfully."
