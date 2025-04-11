#!/bin/bash

set -e  # Exit on error


# Generate a Root CA Certificate (ca.pem)
echo "Generating Root CA Certificate..."
openssl genrsa -out ./default-vault-ca-key.pem 4096
openssl req -x509 -new -nodes -key ./default-vault-ca-key.pem -sha256 -days 365 -out ./default-vault-ca.pem -subj "/CN=Vault"
echo "Root CA Certificate generated."

# Generate a New Client Certificate Signed by CA
echo "Generating Client Key..."
openssl genrsa -out ./default-vault-key.pem 4096
echo "Client Key generated."

# Create a Certificate Signing Request (CSR)default-vault-ca.srl
echo "Creating CSR..."
openssl req -new -key ./default-vault-key.pem -out ./default-vault-cert.pem -subj "/CN=vault" \
-addext "subjectAltName =  DNS:vault, DNS:vault-node-1, DNS:vault-node-2, DNS:vault-node-3, DNS:vault-node-4, DNS:vault-node-5"
echo "CSR created."

# Sign the Client Cert Using Your CA
echo "Signing Client Certificate..."
openssl x509 -req -in ./default-vault-cert.pem -CA ./default-vault-ca.pem -CAkey ./default-vault-ca-key.pem -CAcreateserial \
-out ./default-vault-cert.pem -days 365 -sha256 \
-extfile <(printf "subjectAltName= DNS:vault, DNS:vault-node-1, DNS:vault-node-2, DNS:vault-node-3, DNS:vault-node-4, DNS:vault-node-5")
echo "Client Certificate signed."

echo "TLS certificate setup completed successfully."
