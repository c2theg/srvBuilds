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



Version:  0.0.1
Last Updated:  12/31/2025

update yourself:
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/setup_webserver.sh && chmod u+x setup_webserver.sh && ./setup_webserver.sh


This downloads and installs a series of scripts that will setup everything needed for a nginx webserver

"

wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_core.sh && chmod u+x update_core.sh && ./update_core.sh && ./install_common.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_python3.sh && chmod u+x install_python3.sh && ./install_python3.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_docker.sh && chmod u+x install_docker.sh && ./install_docker.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/install_resilio.sh && chmod u+x install_resilio.sh && ./install_resilio.sh


#--- Config Files ---
#--- db ---
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/redis.conf
wget -o "mongo.conf" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/mongodb_container.conf

#--- web ---
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/configs/container-nginx.conf

#---- containers ------
docker pull redis:latest
docker pull mongo:latest
docker pull nginx:latest

#-- create containers (You will need to change the path) --

#--- Host settings ---
echo "
[Unit]
Description=Disable Transparent Huge Pages (THP)
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/disable-thp.service

systemctl daemon-reload
systemctl enable disable-thp
systemctl start disable-thp
sudo systemctl enable --now disable-thp.service
#--- end TMP ---
sudo sysctl -w vm.max_map_count=1677716
GLIBC_TUNABLES=glibc.pthread.rseq=0

# Swappiness
#sudo sysctl vm.swappiness=1
sudo sysctl -w vm.swappiness=1
echo "vm.swappiness=1" >> /etc/sysctl.conf


#--- Mongo database ---
docker run \
    -d --name "DB_Cluster1" -p 27017:27017 \
    -v configs/containers/mongodb-cluster/mongo.conf:/etc/mongo.conf \
    -v /var/log/mongodb/:/var/log/mongodb/ \
    --restart=always \
    --ulimit nofile=64000:64000 \
    --memory="8g"  --memory-reservation=512m \
    -v /media/data/containers/mongodb/c0/:/data/db mongo:latest --config /etc/mongo.conf



#--- Redis ---
docker run \
    -d -p 46379:6379 \
    --restart=always \
    --name "Cache0" \
    -m 1g --memory-reservation=512m \
    -v "configs/redis":/redis-conf \
    -v "/var/log/redis":"/var/log/redis" \
    -d redis:latest redis-server /redis-conf

