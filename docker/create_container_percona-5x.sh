#!/bin/sh
#
#   Christopher Gray
#     Version 0.1.4
#     Updated: 9/27/18
#
#   This file is meant for Mac OSX or Linux (Ubuntu / CentOS)
clear

echo "Checking LOCAL directory structure. (/ContainerVolumes/data/sql/mysql).. \r\n \r\n "

if [ ! -d "/ContainerVolumes" ];
then
  mkdir /ContainerVolumes
fi

if [ ! -d "/ContainerVolumes/data" ];
then
  mkdir /ContainerVolumes/data
fi

if [ ! -d "/ContainerVolumes/data/sql" ];
then
  mkdir /ContainerVolumes/data/sql
fi

if [ ! -d "/ContainerVolumes/data/sql/mysql" ];
then
  mkdir /ContainerVolumes/data/sql/mysql
fi

echo "\r\n Downloading config... \r\n \r\n"
wget -O "/ContainerVolumes/data/sql/mysql/mysqld.cnf" "https://github.com/c2theg/srvBuilds/blob/master/configs/mysqld-container.cnf"

echo "Starting container... \r\n \r\n "

docker run -it \
  --hostname MySQL \
  --name=MySQL \
  --net=bridge \
  --expose=3306 \
  -p 3306:3306 \
  -v /ContainerVolumes/data/sql/mysql:/etc/mysql/conf.d \
  -e MYSQL_ROOT_PASSWORD=SecretP@ssw0rd!@# \
  percona:5-stretch \
  --skip-symbolic-links --initialize-insecure --skip-name-resolve


echo "\r\n \r\n DONE! \r\n \r\n"
docker images
docker ps
