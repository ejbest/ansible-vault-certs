import hvac
import os
import datetime  # Corrected import for datetime
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

# Configuration
VAULT_ADDR = "https://localhost:8201"
VAULT_MOUNT = "cert"
VAULT_ROLE = "ansible-client"
VAULT_SECRET_PATH = "secret/data/odri/test"
CA_CERT_FILE = "tls/ca.pem"
CA_KEY_FILE = "tls/ca-key.pem"
CLIENT_CERT_FILE = "tls/client.pem"
CLIENT_KEY_FILE = "tls/client-key.pem"


# Step 1: Generate CA Certificate
def generate_ca_cert():
    print("🔹 Generating CA certificate...")
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

    subject = issuer = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "New York"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "San Francisco"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Nextresearch"),
            x509.NameAttribute(NameOID.COMMON_NAME, "VaultCA"),
        ]
    )

    # Corrected datetime usage
    valid_from = datetime.datetime.utcnow()
    valid_to = valid_from + datetime.timedelta(days=365)

    ca_cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(valid_from)  # ✅ Fixed
        .not_valid_after(valid_to)  # ✅ Fixed
        .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
        .sign(private_key, hashes.SHA256())
    )

    # Save CA key and cert
    os.makedirs("tls", exist_ok=True)
    with open(CA_KEY_FILE, "wb") as f:
        f.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption(),
            )
        )
    with open(CA_CERT_FILE, "wb") as f:
        f.write(ca_cert.public_bytes(serialization.Encoding.PEM))

    print("✅ CA certificate created.")


# Step 2: Generate Client Certificate Signed by CA
def generate_client_cert():
    print("🔹 Generating client certificate...")
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

    subject = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "New York"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "San Francisco"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Nextresearch"),
            x509.NameAttribute(NameOID.COMMON_NAME, "ansible-client"),
        ]
    )

    # Load CA cert and key
    with open(CA_CERT_FILE, "rb") as f:
        ca_cert = x509.load_pem_x509_certificate(f.read())
    with open(CA_KEY_FILE, "rb") as f:
        ca_key = serialization.load_pem_private_key(f.read(), password=None)

    # Corrected datetime usage
    valid_from = datetime.datetime.utcnow()
    valid_to = valid_from + datetime.timedelta(days=365)

    client_cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(ca_cert.subject)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(valid_from)  # ✅ Fixed
        .not_valid_after(valid_to)  # ✅ Fixed
        .add_extension(
            x509.ExtendedKeyUsage([x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH]),
            critical=True,
        )
        .sign(ca_key, hashes.SHA256())
    )

    # Save client key and cert
    with open(CLIENT_KEY_FILE, "wb") as f:
        f.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption(),
            )
        )
    with open(CLIENT_CERT_FILE, "wb") as f:
        f.write(client_cert.public_bytes(serialization.Encoding.PEM))

    print("✅ Client certificate created.")


# Step 3: Configure Vault Cert Auth Method
def configure_vault_cert_auth():
    print("🔹 Configuring Vault certificate authentication...")
    client = hvac.Client(url=VAULT_ADDR, verify=False)

    # Enable cert auth method
    client.sys.enable_auth_method(method_type="cert", path=VAULT_MOUNT)

    # Upload CA certificate
    client.secrets.auth_cert.create_ca_certificate_role(
        name=VAULT_ROLE, certificate=open(CA_CERT_FILE).read()
    )
    print("✅ Vault cert auth configured.")


# Step 4: Authenticate with Vault Using Client Cert
def authenticate_with_vault():
    print("🔹 Authenticating with Vault...")
    client = hvac.Client(
        url=VAULT_ADDR,
        cert=(CLIENT_CERT_FILE, CLIENT_KEY_FILE),
        verify=False,
    )

    # Perform login
    login_response = client.auth.cert.login(name=VAULT_ROLE)
    client.token = login_response["auth"]["client_token"]
    print("✅ Authenticated successfully! Token:", client.token)

    # Test read access
    try:
        secret = client.secrets.kv.v2.read_secret_version(path=VAULT_SECRET_PATH)
        print("🔹 Retrieved secret:", secret["data"])
    except hvac.exceptions.Forbidden:
        print("❌ Permission denied. Check Vault policies.")


# Run all steps
if __name__ == "__main__":
    generate_ca_cert()
    generate_client_cert()
    # configure_vault_cert_auth()
    # authenticate_with_vault()
