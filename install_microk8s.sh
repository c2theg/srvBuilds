#!/bin/sh
# Version: 0.0.1
# Updated: 4/24/2020
#---------------------------
# Source: https://ubuntu.com/kubernetes/install
sudo snap install microk8s --classic
snap info microk8s
sudo snap install microk8s --classic --channel=1.14/stable
microk8s.status
microk8s.status --wait-ready

echo "Done"
