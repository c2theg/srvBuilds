#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear
now=$(date)
echo "Running deploy_nginx-php.sh at $now 
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
Version:  0.1.1                             \r\n
Last Updated:  10/2/2018
\r\n \r\n"
wait
#---------- Download config files ----------------
if [ -s "container-nginx.conf" ]
then
    echo "Deleting old files \r\n"
    rm docker-compose.yml
    rm container-nginx.conf
    rm container-site1.conf
    rm site1_tls.conf
    rm container-php-fpm.ini
    rm docker-compose-nginx_php.yml
    rm sysinfo.php
fi
#--- Nginx Configs
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/container-nginx.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/container-site1.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/site1_tls.conf
#--- PHP Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/container-php-fpm.ini
#--- Docker Deployment Config
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/docker/compose-configs/docker-compose-nginx_php.yml
#--- App Code
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/sysinfo.php
#-----------------------------------------------------------------------------------------------------------------
#--------- Create Directory Structure -------------------------------------------------------------------------
if [ ! -d "/media/data" ]; then
     mkdir /media/data 
fi

if [ ! -d "/media/data/containers" ]; then
     mkdir /media/data/containers/
fi

if [ ! -d "/media/data/containers/nginx" ]; then
     mkdir /media/data/containers/nginx/
     mkdir /media/data/containers/websites/code1/
fi

#--- Create Docker Volume ---
docker volume create nginx

echo "Inspect volume \r\n "
docker volume inspect nginx

#--- rename config file to "docker-compose.yml" -----
mv docker-compose-nginx_php.yml /media/data/containers/nginx/docker-compose.yml

#--- start up container ---
cd /media/data/containers/nginx/

cp sysinfo.php /media/data/containers/websites/code1/index.php
#--- start up container
docker-compose up
#docker-compose -f docker-compose-nginx_php.yml -p Webapp-Nginx-PHP
echo "Done! \r\n \r\n"
