#!/bin/sh
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


Version:  1.6.0
Last Updated:  12/31/2025

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh

Downloading required dependencies...

"
#--------------------------------------------------------------------------------------------
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# curl -fsSL https://get.docker.com/ | sh
sudo -E apt-get update
sudo -E apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-model-plugin
sudo -E apt install -y docker-compose
#-------------------------------------
sudo systemctl start docker
sudo systemctl enable docker
echo "

Done - Showing Versions

"
docker --version
docker-compose -v

#-- add premissions to current user to access: docker.sock --
sudo usermod -aG docker $USER
#------------------------------------------------------------
echo "


Setting up container: Portainer


"
docker pull portainer/portainer-ce:latest
docker volume create portainer_data
docker run \
    --name "Portainer1" \
    -p 8000:8000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    --restart=always \
    -d portainer/portainer-ce:latest

docker ps
 
echo "Visit: https://<server ip>:9443/ to access Portainer"
# Reset Portainer Username: https://omar2cloud.github.io/rasp/psswd/
#---- Other good tools ----
# docker stats
#-- https://hub.docker.com/r/nicolargo/glances
# docker pull nicolargo/glances
#-- 
