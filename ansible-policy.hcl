# Existing KV2 permissions (unchanged)
path "mytest/data/*" {
    capabilities = ["read", "list"]
}
path "mytest/metadata/*" {
    capabilities = ["read", "list"]
}

# 🔹 Allow retrieving AppRole Role ID
path "auth/approle/role/ansible-approle/role-id" {
    capabilities = ["read"]
}

# 🔹 Allow generating new Secret ID
path "auth/approle/role/ansible-approle/secret-id" {
    capabilities = ["create", "update"]
}

# 🔹 Allow logging in with AppRole
path "auth/approle/login" {
    capabilities = ["create", "update"]
}

