import hvac
import urllib3
import os

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Vault Configuration
VAULT_ADDR = "https://localhost:8201"
VAULT_ROLE = "ansible-client"
VAULT_SECRET_PATH = "secret/data/odri/test"

# TLS Certificate Paths
CLIENT_CERT_FILE = "ansible-cert.pem"
CLIENT_KEY_FILE = "ansible-key.pem"
VAULT_CACERT = "ansible-ca.pem"  # Path to your Vault CA certificate


# Step 1: Authenticate with Vault Using Client Certificate (Disabling CA Verification)
def authenticate_with_vault():
    print("🔹 Authenticating with Vault (Disabling CA verification)...")

    # Option 1: If Vault CA is correct, use it
    client = hvac.Client(url=VAULT_ADDR, cert=(CLIENT_CERT_FILE, CLIENT_KEY_FILE))

    try:
        # Perform login
        login_response = client.auth.cert.login(name=VAULT_ROLE)
        client.token = login_response["auth"]["client_token"]
        print("✅ Successfully authenticated! Token:", client.token)
        return client
    except hvac.exceptions.InvalidRequest as e:
        print("❌ Login failed. Check cert settings:", str(e))
        exit(1)


# Step 2: Retrieve a Secret from Vault
def fetch_secret(client):
    print(f"🔹 Fetching secret from: {VAULT_SECRET_PATH}...")

    try:
        secret = client.secrets.kv.v2.read_secret_version(path=VAULT_SECRET_PATH)
        print("✅ Retrieved secret:", secret["data"])
    except hvac.exceptions.Forbidden:
        print("❌ Permission denied. Check Vault policies.")


# Run authentication and fetch secret
if __name__ == "__main__":
    vault_client = authenticate_with_vault()
    fetch_secret(vault_client)
