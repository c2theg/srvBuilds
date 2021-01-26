#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
#clear
echo "\r\n \r\n \r\n 
By: Christopher Gray

Installing 'containerd'

Version:  0.0.1             \r\n
Last Updated:  1/25/2021
\r\n \r\n"
#echo "Updating system first..."
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
wait
#--------------------------------------------
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/

# This section contains the necessary steps to use containerd as CRI runtime.
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#------------ Install containerd ------------------------------
echo "Install containerd  \r\n \r\n"
sudo apt-get update
sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd


echo "All Done"
