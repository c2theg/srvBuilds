#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear

echo "\r\n \r\n Docker Tests \r\n \r\n"


echo "Docker version: (docker version) \r\n "
docker version

echo "\r\n Docker Info: (docker info) \r\n "
docker info

echo "\r\n Docker Images downloaded.. (docker images) \r\n "
docker images

echo "\r\n Docker Containers running: (docker ps) \r\n "
docker ps


echo "\r\n \r\n"
