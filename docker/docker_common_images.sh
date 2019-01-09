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
\r\n \r\n
Version:  0.0.1                             \r\n
Last Updated:  1/9/2019
\r\n \r\n"
#--- download those imageas------
docker pull python:latest
docker pull mongo:latest
docker pull redis:latest
docker pull node:latest
docker pull golang:latest

#--- Typical LNMP ---
#docker pull nginx:latest
# Percona (MySQL 8.x)
#docker pull percona:8
# Percona (MySQL 5.7 is latest)
#docker pull percona:latest
#docker pull php:latest
#docker pull memcached:latest


# Update to the latest images
docker images | grep -v REPOSITORY | awk '{print $1}' | xargs -L1 docker pull

echo "Docker does not overwrite old images, so lets delete them... \r\n "
docker images | grep "<none>" | awk '{print $3}' | xargs -L1 docker rmi


echo "Remove docker images with: \r\n \r\n"
echo "docker images -a \r\n \r\n"
echo "docker rmi image <Number> \r\n \r\n"
echo "Update: docker images |grep -v REPOSITORY|awk '{print $1}'|xargs -L1 docker pull  \r\n \r\n"
echo "Delete old docker images: docker images | grep "<none>" | awk '{print $3}' | xargs -L1 docker rmi \r\n \r\n"

echo "DONE!"
