#!/bin/bash

set -x
source ~/.bash_profile

# Vault token is now sourced from .bash_profile
export VAULT_TOKEN="$VAULT_TOKEN"

# Vault addresses sourced from .bash_profile
VAULT_ADDRESSES=("${VAULT_ADDRESSES[@]}")

# Unseal keys sourced from .bash_profile
UNSEAL_KEYS=("${UNSEAL_KEYS[@]}")

# Function to check Vault status
check_vault_status() {
    vault status
}

# Function to check if Vault is sealed
is_vault_sealed() {
    check_vault_status | grep -q "Sealed\s*true"
}

# Function to unseal Vault
unseal_vault() {
    # Unseal each Vault address using the stored keys
    for addr in "${VAULT_ADDRESSES[@]}"; do
        export VAULT_ADDR="$addr"  # Set the VAULT_ADDR for the current iteration
        for key in "${UNSEAL_KEYS[@]}"; do
            vault operator unseal "$key"
        done

        # Check the unseal status for each Vault address
        check_vault_status
    done
}

# Loop through each Vault address
for addr in "${VAULT_ADDRESSES[@]}"; do
    export VAULT_ADDR="$addr"  # Set the VAULT_ADDR for the current iteration

    # Check Vault status
    echo "Checking Vault status for $addr"
    check_vault_status

    # Check if Vault is sealed
    if is_vault_sealed; then
        echo "Vault is sealed. Unsealing..."
        unseal_vault
    else
        echo "Vault is already unsealed."
    fi
done
