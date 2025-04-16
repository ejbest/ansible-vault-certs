#!/bin/bash

echo "Checking for Minikube installation..."

MINIKUBE_PATH=$(which minikube 2>/dev/null)

if [ -z "$MINIKUBE_PATH" ]; then
    echo "Minikube is not installed."
    exit 0
else
    echo "Minikube found at: $MINIKUBE_PATH"
fi

# Stop and delete any running minikube cluster
echo "Stopping and deleting Minikube cluster (if any)..."
minikube stop || true
minikube delete || true

# Remove Minikube binary
echo "Removing Minikube binary..."
sudo rm -f "$MINIKUBE_PATH"

# Clean up Minikube config and cache
echo "Removing Minikube configuration and cache..."
rm -rf ~/.minikube

# Remove Minikube context from kubectl
if command -v kubectl >/dev/null 2>&1; then
    echo "Cleaning up kubectl contexts related to Minikube..."
    kubectl config delete-context minikube 2>/dev/null || true
    kubectl config unset users.minikube 2>/dev/null || true
    kubectl config unset clusters.minikube 2>/dev/null || true
else
    echo "kubectl not found, skipping kubeconfig cleanup."
fi

# Optionally remove ~/.kube if you only used Minikube
read -p "Do you want to remove the entire ~/.kube directory? (y/N): " REMOVE_KUBE
if [[ "$REMOVE_KUBE" =~ ^[Yy]$ ]]; then
    echo "Removing ~/.kube..."
    rm -rf ~/.kube
else
    echo "Keeping ~/.kube directory."
fi

echo "Minikube has been completely removed."
