#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
#
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
Version:  0.0.8                             \r\n
Last Updated:  3/25/2021
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait

#echo "Source: https://www.howtoforge.com/tutorial/install-mongodb-on-ubuntu/  \r\n ";

echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing gnupg, openssl.. "
sudo apt-get install -y gnupg

echo "Adding Key... "
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

#------------- OS Version Detection -------------
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo " Detected: OS: $OS, Version: $VER \r\n \r\n"
#-----------------------------------------------
if [ $VER = '14.04' ]; then
    wait
    echo "14.04"
    echo "Mongo not supported on this version of Ubuntu"
else
    if [ $VER = '16.04' ]; then
    	wait
    	echo "16.04"
     sudo apt-get install -y libcurl3
     echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    elif [ $VER = '18.04' ]; then
    	wait
    	echo "18.04"
     sudo apt-get install libcurl4
     echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    elif [ $VER = '20.04' ]; then
    	wait
    	echo "20.04"
     sudo apt-get install libcurl4
     echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    
    
    fi
fi
#-------------------------------------
echo "Updating repo's... \r\n \r\n "
sudo apt-get update

#MongoDBVersion=4.4.1
#echo "Install Mongodb $MongoDBVersion ... "
#sudo apt-get install -y mongodb-org=$MongoDBVersion mongodb-org-server=$MongoDBVersion mongodb-org-shell=$MongoDBVersion mongodb-org-mongos=$MongoDBVersion mongodb-org-tools=$MongoDBVersion
sudo apt-get install -y mongodb-org


# For NGINX / Apache - PHP
# sudo apt-get install php7.4-mongodb

#----------------------------------
ps --no-headers -o comm 1

ps -e | grep mongo

#sudo -E apt-get update
#sudo apt-get install -y mongodb-org --allow-unauthenticated

systemctl start mongod
systemctl enable mongod
netstat -plntu

echo "Done. Starting Mongo (from config: /etc/mongod.conf) ..."
#sudo service mongod start
sudo -u mongodb mongod --config /etc/mongod.conf

sudo service mongod status

echo " Use any of the following to get info from Mongo: \r\n
mongo -port 27017   \r\n \r\n
 
db.version()     \r\n
rs.status()     \r\n
rs.conf()     \r\n
db.isMaster()     \r\n \r\n
"

#connect to mongo
mongo -port 27017
