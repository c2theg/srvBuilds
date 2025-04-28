#!/bin/bash
#---------------------------
#  By: Christopher Gray
#  Updated: 4/27/2025
#  Version: 0.0.15
#
#  Sources:
#		https://docs.frigate.video/frigate/installation/
#		https://docs.frigate.video/frigate/installation/#docker
#
#
#	Install This:
#	    wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/nvr/install_frigate.sh && chmod u+x install_frigate.sh && ./install_frigate.sh
#
#---------------------------
sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y apt-transport-https software-properties-common ca-certificates

sudo apt install -y unattended-upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades


# - Recommend installing all updates first
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ubuntu14.04.sh && chmod u+x update_ubuntu14.04.sh && ./update_ubuntu14.04.sh


# Install Docker first! 
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh

docker --version
docker-compose -v

#--- create dir structure ---
mkdir -p /media/frigate/config
mkdir -p /media/frigate/clips
mkdir -p /media/frigate/recordings
mkdir -p /media/frigate/exports
mkdir -p /tmp/cache
mkdir -p /dev/shm


# Download Better Example Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/nvr/config.yml && mv config.yml /media/frigate/config/config.yaml

#----- setup frigate docker container ------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/nvr/frigate_docker-compose.yml
cp frigate_docker-compose.yml docker-compose.yml

docker image prune -f

echo "


Now Visit:  https://docs.frigate.video/guides/getting_started/


You WILL need to edit the file:   

		nano  /media/frigate/config/config.yaml 



Once your done, start by using: 'docker compose up'
ONCE you know your config works correctly. Auto start docker compose on startup with:  'docker compose up -d'


Visit Frigate at:  <IP-Address>:5000


-- starting anyway - use: ctrl+c to stop containers


"
docker compose up
