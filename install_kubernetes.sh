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
Version:  0.0.2                             \r\n
Last Updated:  9/2/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
wait
sudo -E apt-get upgrade -y
wait
  
    # from: https://github.com/hobby-kube/guide
    echo "Installing Kubernetes....  \r\n"
    echo "Learning more about it here: https://kubernetes.io/docs/tutorials/kubernetes-basics/" 
    echo "\r\n \r\n"
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
    wait
    sudo -E apt-get update
    sudo -E apt-get install -y kubelet kubeadm kubectl kubernetes-cni
    wait
    echo "\r\n \r\n Trying to use SNAP (Ubuntu 16.04+ to install Kubernetes... \r\n "
    sudo snap install conjure-up --classic
    sudo apt install -y conjure-up
    wait
    sudo conjure-up kubernetes
