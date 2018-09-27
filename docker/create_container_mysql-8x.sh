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

if [ ! -d "/media/data/sql" ]; then
then
  mkdir /media/data/sql
fi

if [ ! -d "/media/data/sql/mysql" ]; then
then
  mkdir /media/data/sql/mysql
fi

echo "Starting container... \r\n \r\n "

docker run -it --hostname MySQL --name=MySQL --net=bridge --expose=3306 -p 3306:3306 -v ~/data:/media/data/sql/mysql -e MYSQL_ROOT_PASSWORD=SecretP@ssw0rd!@# mysql:8

echo "\r\n \r\n DONE! \r\n \r\n"
docker images
