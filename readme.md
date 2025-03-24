# Generate a Root CA Certificate (ca.pem)

# step 1 this generates certs(this step is done by Certificate Team)
run ansible_certs.sh

# Start the vault container

```
docker-compose up -d
```

# Enable cert auth method

## Exec into the container.

```
docker exec -it vault /bin/sh
```

### Init vault

```
vault operator init
```

### Unseal Vault
Unseal Key 1: Kb3JU67yeBwYvr8+m7F+UA6CY2cs7DMpTm97zIR8qMjk
Unseal Key 2: QgyRU+WyxoucwjHmNIBSscN7VNSICF0NnjJDjCbYTYFk
Unseal Key 3: a3izzqtC6hVaq7tDjh7SoUWN6zNMTvIrgqlF4EzOo24U
Unseal Key 4: xTZxlNAralEUTsr4VexSb2RblzPAAiTJNxoGAhIB3Djz
Unseal Key 5: BSFswFqGgOzyuJnW4LwjOIJwSPrcVvpWZrUCbncxBvMm

Initial Root Token: hvs.xPy1TAcBaSYhyacyHpp5kB4d

```
vault operator unseal
```

Exit.

# Add Secret to Vault

# Enable cert auth method and Create a Vault policy for Ansible

Run ansible_vault_cert_auth.sh script

# Test ansible playbook to retrieve secret

```
ansible-playbook ansible-playbook.yaml
```
