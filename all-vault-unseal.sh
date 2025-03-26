#!/bin/bash

# Set the Vault token
# Must already be setup with key vars 

# Array of Vault addresses to check
VAULT_ADDRESSES=(
    "https://127.0.0.1"	    #one
    "https://127.0.0.1"		#two
    "https://127.0.0.1"     #three
)

UNSEAL_KEYS_FILE="/home/wsluser/.ssh/unseal_keys.txt"

# Function to check Vault status
check_vault_status() {
    vault status
}

# Function to check if Vault is sealed
is_vault_sealed() {
    check_vault_status | grep -q "1Sealed\s*true"
}

# Function to unseal Vault
unseal_vault() {
    # Read unseal keys from the file
    UNSEAL_KEYS=$(cat "$UNSEAL_KEYS_FILE")

    # Unseal each Vault address using the stored keys
    for addr in "${VAULT_ADDRESSES[@]}"; do
        export VAULT_ADDR="$addr"  # Set the VAULT_ADDR for the current iteration
        for key in $UNSEAL_KEYS; do
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

