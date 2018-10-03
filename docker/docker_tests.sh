#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear

echo "\r\n \r\n Docker Tests \r\n \r\n"
echo " Link: https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes  \r\n \r\n"

echo "Docker version: (docker version) \r\n "
docker version

echo "\r\n Docker Info: (docker info) \r\n "
docker info

echo "\r\n Docker Images downloaded.. (docker images -a) \r\n "
docker images -a

echo "\r\n Docker Containers running: (docker ps -a) \r\n "
docker ps -a
echo "\r\n \r\n"
docker ps

echo "\r\n Docker Volumes: (docker volume ls) \r\n "
docker volume ls

echo "\r\n Docker Networking: (docker network inspect bridge) \r\n "
docker network inspect bridge

echo "\r\n Cheat sheet for deleting a container: https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes  \r\n \r\n "


echo "\r\n---------------- DEBUG Commands ---------------------------- \r\n \r\n"
echo "SSH into nginx container: docker exec -it nginx /bin/bash \r\n "




echo "\r\n \r\n"
