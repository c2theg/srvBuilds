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
Version:  0.0.4                             \r\n
Last Updated:  1/5/2020
\r\n \r\n"
#sudo -E apt-get update
#wait
#sudo -E apt-get upgrade -y
#wait

#echo "Source: https://www.howtoforge.com/tutorial/install-mongodb-on-ubuntu/  \r\n ";

echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
echo "Installing gnupg.. "
sudo apt-get install -y gnupg openssl

#--- Ubuntu 16.04 ---
sudo apt-get install -y libcurl3
#--- Ubuntu 18.04 ---
#sudo apt-get install libcurl4

echo "Adding Key... "
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
#--- Ubuntu 16.04 (Xenial) ---
# /etc/apt/sources.list.d/mongodb-org-4.2.list
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
#--- Ubuntu 18.04 (Bionic) ----
#echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

#-------------------------------------
echo "Updating repo's... \r\n \r\n "
sudo apt-get update

echo "Install Mongodb... "
sudo apt-get install -y mongodb-org=4.2.2 mongodb-org-server=4.2.2 mongodb-org-shell=4.2.2 mongodb-org-mongos=4.2.2 mongodb-org-tools=4.2.2

#----------------------------------
ps -e | grep mongo

#sudo -E apt-get update
#sudo apt-get install -y mongodb-org --allow-unauthenticated

systemctl start mongod
systemctl enable mongod
netstat -plntu

echo "Done. Starting Mongo..."
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
