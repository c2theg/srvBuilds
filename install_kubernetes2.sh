#!/bin/sh
#
clear
echo "
 _____             _         _    _          _                                   
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|                                  
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _                                   
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|                                  
                                     |___|                                       
                                                                                 
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|
\r\n \r\n
Version:  0.1.1                             \r\n
Last Updated:  10/20/2025
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait



echo "Disable Swap: Kubernetes requires swap to be disabled. \r\n \r\n"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab



echo "\r\n \r\n Add Kernel Parameters: Load necessary kernel modules and configure sysctl parameters. \r\n \r\n"
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


sudo modprobe overlay
sudo modprobe br_netfilter

    
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF


sudo sysctl --system




echo "Install Containerd Runtime: Kubernetes uses a Container Runtime Interface (CRI) compatible runtime like Containerd... \r\n \r\n"

sudo apt install -y containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd



echo "\r\n \r\n Add Kubernetes Apt Repository. \r\n \r\n"
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update




echo "Install Kubeadm, Kubelet, and Kubectl: \r\n \r\n"
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl



echo "\r\n \r\n 
Control Plane Node Specific Steps: \r\n 
Initialize Kubernetes Cluster.   \r\n \r\n "
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 # Or your chosen CNI's CIDR



echo "\r\n \r\n Follow the instructions in the output to configure kubectl for your user.
Install Network Plugin (e.g., Calico):
\r\n \r\n"

# VERY Slow to load sometimes, so hosting in my repo
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/calico.yaml



echo "\r\n \r\n Remove Taint (Optional): If you want to schedule pods on the control plane node. \r\n \r\n "
kubectl taint nodes --all node-role.kubernetes.io/control-plane-



echo "\r\n \r\n Worker Node Specific Steps: \r\n \r\n"
echo "Join Worker Node to Cluster: Use the kubeadm join command provided in the output of the kubeadm init command from the control plane node. \r\n \r\n "

sudo kubeadm join <control-plane-ip>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>


echo "\r\n \r\n Verification: \r\n \r\n"
echo "On the control plane node, verify the cluster status: \r\n \r\n"
kubectl get nodes
kubectl get pods -A



