#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
clear

# create directory structure

if [ ! -d "/media/data" ]; then
then
  mkdir /media/data 
fi

if [ ! -d "/media/data/nosql" ]; then
then
  mkdir /media/data/nosql
fi

if [ ! -d "/media/data/nosql/mongo1" ]; then
then
  mkdir /media/data/nosql/mongo1
fi

echo "Starting container... \r\n \r\n "

docker run -d -p 27017:27107 -v ~/data:/media/data/nosql/mongo1 mongo:4-xenial

echo "\r\n \r\n DONE! \r\n \r\n"
docker images
