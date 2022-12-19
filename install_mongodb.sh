#!/bin/sh
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
Version:  0.0.10                             \r\n
Last Updated:  12/19/2022
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait

# Source: https://techviewleo.com/install-mongodb-on-ubuntu-linux/

echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing gnupg, openssl.. "
sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

echo "Adding Key... "
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-6.gpg

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
    if [ $VER = '20.04' ]; then
    	   wait
    	   echo "20.04"
        sudo apt-get install libcurl4
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

    elif [ $VER = '22.04' ]; then
        wait
    	   echo "22.04"
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
        sudo dpkg -i ./libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
   
    
    fi
fi
#-------------------------------------
echo "Updating repo's... \r\n \r\n "
#sudo apt-get update
#sudo apt-get install -y mongodb-org

sudo apt update
sudo apt install -y mongodb-org

# For NGINX / Apache - PHP
# sudo apt-get install php7.4-mongodb

#----------------------------------
sudo chown -R mongodb:mongodb /var/log/mongodb/*

#ps --no-headers -o comm 1
#ps -e | grep mongo

#sudo -E apt-get update
#sudo apt-get install -y mongodb-org --allow-unauthenticated

#systemctl start mongod
#systemctl enable mongod
#netstat -plntu

sudo systemctl enable --now mongod
mongod --version
#

#-- backup original copy and replace with custom config --
mv /etc/mongod.conf /etc/mongod_original.conf
wget https://raw.githubusercontent.com/c2theg/srvBuilds/master/configs/mongodb_standalone.conf
mv mongodb_standalone.conf /etc/mongod.conf

mkdir -p /media/data/mongodb/shards/c1
sudo chown -R mongodb:mongodb /media/data/mongodb/shards/c1/*


echo "Done. Starting Mongo (from config: /etc/mongod.conf) ..."
#sudo systemctl restart mongod
sudo service mongod start
#sudo -u mongodb mongod --config /etc/mongod.conf

#sudo service mongod status

echo " Use any of the following to get info from Mongo: \r\n
mongo -port 27018   \r\n \r\n
 
db.version()     \r\n
rs.status()     \r\n
rs.conf()     \r\n
db.isMaster()     \r\n \r\n
"

#connect to mongo
#mongo -port 27018

echo "\r\n \r\n Or use Mongo Compass! \r\n \r\n "
