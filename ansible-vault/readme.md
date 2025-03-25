# Generate a Root CA Certificate (ca.pem)

# Start the vault container
### Init vault
```
vault operator init
```
### Unseal Vault
vault operator unseal
```
docker-compose up -d
```

# step 1 this generates certs(this step is done by Certificate Team)
run ansible_certs.sh


# Enable cert auth method

## Exec into the container.

```
docker exec -it vault /bin/sh
```

```

Exit.

# Add Secret to Vault

# Enable cert auth method and Create a Vault policy for Ansible

Run ansible_vault_cert_auth.sh script

# Test ansible playbook to retrieve secret

```
ansible-playbook ansible-playbook.yaml
```
