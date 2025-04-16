#!/bin/bash
set -e

### CONFIGURATION ###
MASTER_IP="$(ip -4 addr show | grep ens18 | grep "inet" | head -1 | awk '{print $2}' | cut -d/ -f1)"
K8S_VERSION="1.30"
K8S_VERSION_MINOR="1.30.5"
POD_CIDR="10.1.1.0/16"
SERVICE_CIDR="10.96.0.0/12"
HELM_VERSION="1.16.3"

echo "[Step 1] Installing Kernel Headers"
sudo dnf install -y kernel-devel-$(uname -r)

echo "[Step 2] Loading Kernel Modules"
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF

for module in br_netfilter ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh overlay; do
  sudo modprobe $module
done

echo "[Step 3] Configuring Sysctl"
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

echo "[Step 4] Disabling Swap"
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

echo "[Step 5] Installing Containerd"
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf makecache
sudo dnf install -y containerd.io

echo "[Step 5.1] Configuring Containerd"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd
sleep 3
sudo systemctl status containerd --no-pager

echo "[Step 6] Configuring Firewall"
for port in 6443 2379-2380 10250 10251 10252 10255 5473; do
  sudo firewall-cmd --zone=public --permanent --add-port=$port/tcp
done
sudo firewall-cmd --reload

echo "[Step 7] Installing Kubernetes Components"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${KUBE_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${KUBE_VERSION}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo dnf makecache
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# ------ MASTER NODE ONLY ------
if [[ "$HOSTNAME" == "master" ]]; then
  echo "[Step 8] Initializing Kubernetes Control Plane"
  sudo kubeadm config images pull
  sudo kubeadm init --pod-network-cidr=$POD_CIDR
  kubeadm init --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --upload-certs --kubernetes-version=v$K8S_VERSION_MINOR --control-plane-endpoint=$CONTROL_PLANE --ignore-preflight-errors=all --cri-socket unix:///run/containerd/containerd.sock  

  echo "[Step 8.1] Configuring kubectl access for current user"
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  echo "[Step 8.2] Installing Flannel Network Plugin"
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  echo "[Step 8.3] Get the join command for worker nodes:"
  kubeadm token create --print-join-command
fi



# Deploy Cilium CNI
echo "Deploy Cilium CNI"
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium  --namespace kube-system --version $HELM_VERSION
