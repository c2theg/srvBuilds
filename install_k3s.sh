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


Version:  0.0.10
Last Updated:  2/25/2025


Install:
    rm install_k3s.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_k3s.sh && chmod u+x install_k3s.sh



Sources:
    https://www.digitalocean.com/community/tutorials/how-to-setup-k3s-kubernetes-cluster-on-ubuntu
    https://docs.k3s.io/quick-start

  
"

#-- update yourself! --
rm install_k3s.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_k3s.sh && chmod u+x install_k3s.sh

#--------------------------------------------------------------------------------------------
echo "Un REM the install you want to do "

#--- Install on Master / Primary Node ---
# curl -sfL https://get.k3s.io | sh -


#--- disable traefik loadbalancer ---
# curl -sfL https://get.k3s.io  | INSTALL_K3S_EXEC="--disable=traefik" sh -


#--- Installing on a replicate / slave node
# curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -


#--- High Availability Embedded etcd  -  https://docs.k3s.io/datastore/ha-embedded  ---
# curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
#    --cluster-init \
#    --tls-san=<FIXED_IP> # Optional, needed if using a fixed registration address





wait(10)
systemctl status k3s

sudo kubectl get all -n kube-system

sudo chmod 644 /etc/rancher/k3s/k3s.yaml






