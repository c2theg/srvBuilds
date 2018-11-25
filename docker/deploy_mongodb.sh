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
Version:  0.0.5                             \r\n
Last Updated:  11/24/2018
\r\n \r\n"

# wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/deploy_mongodb.sh && chmod u+x deploy_mongodb.sh && ./deploy_mongodb.sh

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
mv docker-compose_mongodb.yml /media/data/containers/mongodb1/docker-compose.yml

#--- start up container ---
cd /media/data/containers/mongodb1/

echo "\r\n \r\n"
echo "Access Container with the following:  \r\n \r\n docker exec -it mongodb /bin/bash   \r\n \r\n"

echo "----------------------------------------- \r\n \r\n"
echo "A few Mongodb commands: \r\n \r\n"

echo "Start client: mongo  \r\n \r\n"
echo "Info: db.help() \r\n \r\n"
echo "Info: db.stats() \r\n \r\n"
echo "More info: https://www.tutorialspoint.com/mongodb/mongodb_create_database.htm "

echo "\r\n \r\n Done! \r\n \r\n"

docker-compose up -d
