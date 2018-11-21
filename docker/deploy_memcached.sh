#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running deploy_memcached.sh at $now 
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
Version:  0.0.4                             \r\n
Last Updated:  11/20/2018
\r\n \r\n"
wait
#---------- Download config files ----------------
if [ -s "docker-compose.yml" ]
then
    echo "Deleting old files \r\n"
    rm docker-compose.yml
#    rm container-memcached.conf
    rm docker-compose-memcache.yml
fi
#--- Memcached Config
#wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/container-memcached.conf
#--- Docker Deployment Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/compose-configs/docker-compose-memcache.yml
#--------- Create Directory Structure ------------------------------------------------------------------------------
if [ ! -d "/media/data" ]; then
     mkdir /media/data 
fi

if [ ! -d "/media/data/containers" ]; then
     mkdir /media/data/containers/
fi

if [ ! -d "/media/data/containers/memcached" ]; then
     mkdir /media/data/containers/memcached
fi

#--- rename config file to "docker-compose.yml" -----
mv docker-compose-memcache.yml /media/data/containers/memcached/docker-compose.yml
#--- start up container ---
cd /media/data/containers/memcached
docker-compose up
echo "Done! \r\n \r\n"
