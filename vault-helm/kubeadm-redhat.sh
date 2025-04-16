#!/bin/bash
# Installing WireGuard and Kubernetes on Red Hat-based systems

CONTROL_PLANE="$(ip -4 addr show | grep ens18 | grep 'inet' | head -1 | awk '{print $2}' | cut -d/ -f1)"
K8S_VERSION="1.30"
K8S_VERSION_MINOR="1.30.5"
POD_CIDR="10.1.1.0/16"
SERVICE_CIDR="10.96.0.0/12"
HELM_VERSION="1.16.3"

echo "Step 1 - Install Helm, kubectl, kubeadm, and kubelet $K8S_VERSION"

# Update system and install dependencies
sudo dnf install -y epel-release
sudo dnf install -y curl wget gnupg2 ca-certificates yum-utils device-mapper-persistent-data lvm2

# Disable swap
echo "Disabling swap"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

# Enable kernel modules
echo "Enabling required kernel modules"
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/modules-load.d/containerd.conf <<EOF > /dev/null
overlay
br_netfilter
EOF

# Apply sysctl settings
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF > /dev/null
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install containerd
echo "Installing containerd"
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable --now containerd

# Add Kubernetes repository
echo "Adding Kubernetes repository"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo > /dev/null
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/rpm/repodata/repomd.xml.key
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Pull images and initialize cluster
echo "Pulling Kubernetes images"
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v$K8S_VERSION_MINOR

echo "Initializing Kubernetes control plane"
sudo kubeadm init \
  --pod-network-cidr=$POD_CIDR \
  --service-cidr=$SERVICE_CIDR \
  --upload-certs \
  --kubernetes-version=v$K8S_VERSION_MINOR \
  --control-plane-endpoint=$CONTROL_PLANE \
  --ignore-preflight-errors=all \
  --cri-socket unix:///run/containerd/containerd.sock

# Configure kubectl for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Helm
echo "Installing Helm"
wget https://get.helm.sh/helm-v3.12.1-linux-amd64.tar.gz -O helm.tar.gz
tar -xvzf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm.tar.gz

# Deploy Cilium
echo "Deploying Cilium CNI"
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system --version $HELM_VERSION
