#!/bin/sh

#--- download those imageas------
docker pull python:latest
docker pull mongo:latest
docker pull redis:latest
docker pull node:latest
docker pull golang:latest
#--- optional ---
docker pull php:latest
docker pull nginx:latest
#docker pull memcached:latest
# Percona (MySQL 8.x)
docker pull percona:8
# Percona (MySQL 5.7 is latest)
#docker pull percona:latest


# Update to the latest images
docker images | grep -v REPOSITORY | awk '{print $1}' | xargs -L1 docker pull

echo "Docker does not overwrite old images, so lets delete them... \r\n "
docker images | grep "<none>" | awk '{print $3}' | xargs -L1 docker rmi


echo "remove docker images with: \r\n \r\n"
echo "docker images -a \r\n \r\n"
echo "docker rmi image <Number> \r\n \r\n"
echo "Update: docker images |grep -v REPOSITORY|awk '{print $1}'|xargs -L1 docker pull  \r\n \r\n"
echo "Delete old docker images: docker images | grep "<none>" | awk '{print $3}' | xargs -L1 docker rmi \r\n \r\n"
