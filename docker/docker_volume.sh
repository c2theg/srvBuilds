#!/bin/sh

if [ ! -d "/media/data" ]; then
     mkdir /media/data 
fi

if [ ! -d "/media/data/containers" ]; then
     mkdir /media/data/containers/
fi
#-----------------------------------------------------
echo "\r\n Create volume 'ContainerVolumes' \r\n "
docker volume create ContainerVolumes

echo "\r\n Inspect the volume... \r\n \r\n"
docker volume inspect ContainerVolumes

echo "\r\n All Volumes... \r\n \r\n"
docker volume ls
