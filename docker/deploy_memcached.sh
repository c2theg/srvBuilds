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
Version:  0.0.1                             \r\n
Last Updated:  10/2/2018
\r\n \r\n"
wait
#---------- Download config files ----------------
if [ -s "docker-compose.yml" ]
then
    echo "Deleting old files \r\n"
    rm docker-compose.yml
    rm container-memcached.conf
    rm docker-compose-memcache.yml
fi
#--- Memcached Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/container-memcached.conf
#--- Docker Deployment Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/compose-configs/docker-compose-memcache.yml
#-----------------------------------------------------------------------------------------------------------------
#--- rename config file to "docker-compose.yml"
mv docker-compose-memcache.yml docker-compose.yml
#--- start up container
docker-compose up
echo "Done! \r\n \r\n"
