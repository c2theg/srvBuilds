#!/bin/sh

echo "\r\n Create volume 'ContainerVolumes' \r\n "
docker volume create ContainerVolumes


echo "\r\n Inspect the volume... \r\n \r\n"
docker volume inspect ContainerVolumes


echo "\r\n All Volumes... \r\n \r\n"
docker volume ls
