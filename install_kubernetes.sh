#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
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
Version:  0.0.7                             \r\n
Last Updated:  1/25/2021
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
echo "Installing Wireguard VPN.. \r\n "
sudo -E apt install wireguard

# from: https://github.com/hobby-kube/guide
echo "Installing Kubernetes....  \r\n"
echo "Learning more about it here: https://kubernetes.io/docs/tutorials/kubernetes-basics/" 
echo "\r\n \r\n"
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add 
wait
wait
#echo 'deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main' >> /etc/apt/sources.list.d/kubernetes.list
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
wait
sudo -E apt-get update
sudo -E apt-get install -y kubelet kubeadm kubectl kubernetes-cni
wait
echo "\r\n \r\n Trying to use SNAP (Ubuntu 16.04+ to install Kubernetes... \r\n "
sudo snap install kubectl --classic
sudo snap install conjure-up --classic
sudo apt install -y conjure-up
wait
sudo conjure-up kubernetes
wait
wait
echo "Initialize your master
With everything installed, go to the machine that will serve as the Kubernetes master and issue the command:  sudo kubeadm init \r\n \r\n "
#sudo kubeadm init

# https://kubernetes.io/docs/tasks/access-application-cluster/service-access-application-cluster/
kubectl version

#------ Firewall Rules ------------

ufw allow ssh # sshd on port 22, be careful to not get locked out!
ufw allow 6443 # remote, secure Kubernetes API access
ufw allow 80
ufw allow 443
# open VPN port on private network interface (use eth0 on Hetzner Cloud)
ufw allow in on eth1 to any port 51820
ufw allow in on eth1 to any port 61820
# allow all traffic on VPN tunnel interface
ufw allow in on wg0

ufw default deny incoming # deny traffic on every other port, on any interface
ufw enable

#------- End of FW -----------------

echo "Creating Hello World Cluster \r\n \r\n "
kubectl run hello-world --replicas=2 --labels="run=load-balancer-example" --image=gcr.io/google-samples/node-hello:1.0  --port=8080

echo "\r\n "
kubectl get deployments hello-world
echo "\r\n "
kubectl describe deployments hello-world
echo "\r\n "
kubectl get replicasets
echo "\r\n "
kubectl describe replicasets
echo "\r\n "
kubectl cluster-info
