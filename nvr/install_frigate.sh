#!/bin/bash
#---------------------------
#  By: Christopher Gray
#  Updated: 4/27/2025
#  Version: 0.0.10
#
#  Sources:
#		https://docs.frigate.video/frigate/installation/
#
#---------------------------
sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y apt-transport-https software-properties-common ca-certificates

# - Recommend installing all updates first
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ubuntu14.04.sh && chmod u+x update_ubuntu14.04.sh && ./update_ubuntu14.04.sh


# Install Docker first! 
# wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh

#--- create dir structure ---
mkdir -p /media/frigate/config
mkdir -p /media/frigate/clips
mkdir -p /media/frigate/recordings
mkdir -p /media/frigate/exports
mkdir -p /tmp/cache
mkdir -p /dev/shm

#----- setup frigate docker container ------
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/nvr/frigate_docker-compose.yml
cp frigate_docker-compose.yml docker-compose.yml
#   docker compose up
docker-compose -f docker-compose.yml up --remove-orphans
