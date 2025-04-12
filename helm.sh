#!/bin/bash -x 

# Build the image inside the minikube
eval $(minikube docker-env)


# Deploy vault using helm
helm upgrade --install vault ./vault-helm \
  --namespace vault \
  --create-namespace \
  --timeout 720s \
  --force
