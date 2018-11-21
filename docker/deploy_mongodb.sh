#!/bin/sh
clear
now=$(date)
echo "Running deploy_mongodb.sh at $now 
  _____             _             
 |  __ \           | |            
 | |  | | ___   ___| | _____ _ __ 
 | |  | |/ _ \ / __| |/ / _ \ '__|
 | |__| | (_) | (__|   <  __/ |   
 |_____/ \___/ \___|_|\_\___|_|   
                                  
Created By:
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|
\r\n \r\n
Version:  0.0.2                             \r\n
Last Updated:  11/20/2018
\r\n \r\n"
wait
#---------- Download config files ----------------
if [ -s "docker-compose.yml" ]; then
    echo "Deleting old files \r\n"
    rm docker-compose.yml
#   rm container-mongodb.conf
    rm docker-compose_mongodb.yml
fi
#--- Config ---
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/mongodb.conf
#--- Docker Deployment Config ---
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/compose-configs/docker-compose_mongodb.yml
#--------- Create Directory Structure -------------------------------------------------------------------------
if [ ! -d "/media/data" ]; then
     mkdir /media/data 
fi

if [ ! -d "/media/data/containers" ]; then
     mkdir /media/data/containers/
fi

if [ ! -d "/media/data/containers/mongodb1" ]; then
     mkdir /media/data/containers/mongodb1/
fi

#--- Create Docker Volume ---
docker volume create mongodb1

echo "Inspect volume \r\n "
docker volume inspect mongodb1

#--- rename config file to "docker-compose.yml" -----
mv docker-compose_mongodb.yml /media/data/containers/memcached/docker-compose.yml

#--- start up container ---
cd /media/data/containers/mongodb1/
docker-compose up

echo "Done! \r\n \r\n"
