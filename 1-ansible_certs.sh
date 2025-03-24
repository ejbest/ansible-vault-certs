#!/bin/bash

set -e  # Exit on error

# script goal.......creates TLS CA and Client Certificates 
# CA - certificate authority 
#  Plays 2 roles 
#    Signing TLS Client Certificates for Authentication
#    Adding the CA Certificate to a Vault Role for Ansible
# 
# 
# A CA (Certificate Authority) certificate is essential in TLS authentication because it establishes trust between clients and servers. 
# In your case, you used the CA certificate for two main purposes:
# Signing TLS Client Certificates for Authentication
# You used the CA certificate to sign the TLS client certificates.
# These signed client certificates are used for authentication in the cert auth method in HashiCorp Vault.
# When a client presents a TLS certificate, Vault checks if it is signed by the trusted CA before granting access.
# Adding the CA Certificate to a Vault Role for Ansible
# In the cert authentication method, Vault allows defining roles that map client certificates to specific policies.
# You added the CA certificate to a role in the cert auth method to allow Ansible (or other clients) to authenticate using their TLS client certificates.
# This ensures that only certificates signed by the trusted CA can be used to authenticate and interact with Vault.
# Create TLS directory if it doesn't exist
mkdir -p tls

# Generate a Root CA Certificate (ca.pem)
echo "Generating Root CA Certificate..."
openssl genrsa -out tls/tls-ca-key.pem 4096
openssl req -x509 -new -nodes -key tls/tls-ca-key.pem -sha256 -days 365 -out tls/tls-ca.pem -subj "/CN=Vault CA"
echo "Root CA Certificate generated."

# Generate a New Client Certificate Signed by CA
echo "Generating Client Key..."
openssl genrsa -out tls/tls-key.pem 4096
echo "Client Key generated."

# Create a Certificate Signing Request (CSR)
echo "Creating CSR..."
openssl req -new -key tls/tls-key.pem -out tls/tls-csr.pem -subj "/CN=localhost" \
-addext "subjectAltName = IP:127.0.0.1,DNS:ansible-client"
echo "CSR created."

# Sign the Client Cert Using Your CA
echo "Signing Client Certificate..."
openssl x509 -req -in tls/tls-csr.pem -CA tls/tls-ca.pem -CAkey tls/tls-ca-key.pem -CAcreateserial \
-out tls/tls-cert.pem -days 365 -sha256 \
-extfile <(printf "subjectAltName=IP:127.0.0.1,DNS:ansible-client")
echo "Client Certificate signed."

echo "TLS certificate setup completed successfully."