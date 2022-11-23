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
Version:  1.5.9                             \r\n
Last Updated:  11/23/2022

"
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
sudo apt-get install -y apt-transport-https software-properties-common ca-certificates

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# curl -fsSL https://get.docker.com/ | sh
sudo -E apt-get update
apt-cache policy docker-ce
sudo -E apt-get install -y docker-ce
sudo -E apt install -y docker-compose

#-------------------------------------
sudo systemctl start docker
#sudo systemctl status docker
sudo systemctl enable docker
#wait
#sudo systemctl status docker


#-------------------------------------
docker pull portainer/portainer-ce:latest
